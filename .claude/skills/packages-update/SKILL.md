---
name: packages-update
description: Batch-update this nix-aura repo's pinned Nix dependencies — both the derivations under packages/ and the flake inputs in flake.lock — to their latest upstream versions. Use this skill whenever the user wants to update, bump, or check for new versions of anything this repo pins, whether that is a packages/ entry (ruby-build, leaf, agent-browser) or a flake input (zhtw-mcp, nixpkgs, and friends). Also use when the user says "check for package updates", "bump packages", "update packages", "any new versions?", "有什麼可以更新", asks whether a flake input has fallen behind or how old a pin is, or names one thing like "update leaf" / "bump ruby-build" / "update zhtw-mcp". Covers source-only packages (sha256), Rust packages (also cargoHash), and flake.lock input bumps including verifying the result still builds.
---

# Packages Update

This repo pins its dependencies in two places, and both go stale:

| Where | What it pins | How it moves |
|---|---|---|
| `packages/*.nix` | a GitHub tag, via `fetchFromGitHub` | edit `version` + `sha256` (+ `cargoHash` for Rust) |
| `flake.lock` | another flake's commit | `nix flake update <input>` |

Only the first is visible when reading `packages/`, which is exactly why the second gets forgotten — a flake input can sit months behind without anything in the working tree looking wrong. `check` covers both, so start there regardless of which kind the user named.

## When to use

- User asks whether anything has a new version, without saying which kind
- User asks to bump or update one or more packages
- User names something in `packages/`, or a flake input, and wants it updated

If the user only wants to check, stop after `check`. If they want to update, continue.

## Why a script instead of `nix-update`

`nix-update` is widely used in nixpkgs but is third-party with a large surface (end-to-end version detection + file rewriting + build orchestration in one binary). The script here is intentionally narrow:

- Only handles `fetchFromGitHub` (the only fetcher this repo uses)
- All file-editing logic lives in auditable Python
- Third-party tools it calls (`gh`, `nix-prefetch-github`, `nix build`, `nix-instantiate`) each have narrow scope
- Every edit is followed by `nix-instantiate --parse` to catch breakage early

If the repo grows fetchers (`fetchCrate`, `fetchurl`) or dep-hash kinds (`vendorHash`, `npmDepsHash`), extend `scripts/packages.py` rather than reaching for `nix-update`.

## Workflow

### Step 1: Check

```bash
python3 .claude/skills/packages-update/scripts/packages.py check
```

Prints JSON with two arrays.

`packages` — one entry per GitHub-sourced file under `packages/`, with `version`, `latest_version`, `outdated`, and `cargo_hash` (non-null means the Rust path). A file is read as the derivation it packages: identity and source come from the last `src = fetchFromGitHub` block and the `pname`/`version` declared ahead of it, so whatever else the file fetches — vendored sources a sandboxed build cannot reach the network for, a dependency built alongside — is not mistaken for the package. A file with no such block is skipped, which is also how a source pinned by `rev` rather than by tag stays out: the tag comparison cannot say anything about it, and `packages/spinel.nix` is checked by hand. A `latest_version: null` with an `error` means the upstream publishes neither releases nor tags.

`flake_inputs` — one entry per *direct* input in `flake.lock`, tagged with `kind`:

| `kind` | Meaning | Default stance |
|---|---|---|
| `app` | its name matches a `packages.<system>` attribute, so we build and ship it | bump it; `package_attr` gives `verify` its target |
| `flake` | a library input with no build of its own (e.g. `flake-utils`) | bump it, verify via `.#default` |
| `channel` | a nixpkgs branch | rebuilds the world — propose separately, never fold into a package bump |
| `pinned` | `rev` fixed in `flake.nix` | leave alone; the pin encodes a constraint, and `outdated` is reported as `false` on purpose |
| `unsupported` | not a `github:` input | say so and check by hand |

`behind_by` is best-effort — GitHub declines to compare refs that have diverged enormously, so a `null` count next to `outdated: true` is normal for an old `channel` pin and is not a failure.

Transitive inputs are deliberately not examined: they belong to the flake that declares them, and overriding another project's pin is a different decision from keeping our own current.

### Step 2: Plan

Group by what the user asked for, and by blast radius. `app` and `flake` bumps are routine. A `channel` bump rebuilds everything and deserves its own proposal and its own commit. `pinned` inputs are reported so the picture is complete, not as candidates.

If the user named specific things, filter to those but still mention anything else that turned out to be badly behind — that surprise is the reason `check` covers both tracks.

### Step 3a: Update a `packages/` entry

One package at a time keeps commits clean and lets the user bail mid-batch.

**Prefetch the new source sha256:**

```bash
python3 .claude/skills/packages-update/scripts/packages.py prefetch <OWNER> <REPO> <LATEST_TAG>
```

**Rewrite version + sha256:**

```bash
python3 .claude/skills/packages-update/scripts/packages.py update-source \
  --file packages/<NAME>.nix --version <LATEST_VERSION> --sha256 <SHA256>
```

Both fields are replaced within the derivation the `src` block identifies — the hash under whichever of `hash`/`sha256` the file already uses — and the file is re-parsed before returning. If parse fails the script aborts; investigate rather than retrying.

**Rust only — recompute `cargoHash`.** Skip entirely when `cargo_hash` was `null`:

```bash
python3 .claude/skills/packages-update/scripts/packages.py cargo-hash --file packages/<NAME>.nix
python3 .claude/skills/packages-update/scripts/packages.py update-cargo \
  --file packages/<NAME>.nix --cargo-hash <HASH>
```

`cargo-hash` stages a fake hash, builds through the flake, reads the real hash out of the mismatch error, and restores the file. Building via the flake (rather than `nix-build` on the file) pins it to the flake's nixpkgs instead of the ambient `<nixpkgs>` channel, so the hash matches what the repo actually produces. Cold-cache builds take minutes.

**Commit:**

```bash
git add packages/<NAME>.nix
git commit -m "chore(<pname>): bump <pname> to <latest_version>"
```

Use `latest_version` exactly as it appears in the file — `v20260716` for ruby-build, `1.27.1` for leaf.

### Step 3b: Update a flake input

```bash
nix flake update <INPUT>
git diff flake.lock            # confirm only the intended nodes moved
```

Then build the thing that consumes it, using `package_attr` from `check` (or `default` when that was `null`):

```bash
python3 .claude/skills/packages-update/scripts/packages.py verify --attr <ATTR>
```

Use `verify` rather than a bare `nix build`. It propagates nix's exit code and points at the failing derivation's log. Piping `nix build` into `tail` or `head` reports the *pipe's* status, so a failed build reads as a passing one — and `$PIPESTATUS` does not recover it here, because this shell is zsh (`$pipestatus`). A green build that was never actually green is worse than no check at all.

Evaluating is not building: an input can resolve fine and still fail to compile, because upstream changed its own build. That is what step 4 is for.

Commit separately from package bumps, since the unit of change is the lock file:

```bash
git add flake.lock            # plus flake.nix if the bump required a change there
git commit -m "chore(flake): bump <input> to <short-rev-or-version>"
```

### Step 4: When a bumped input no longer builds

Upstream owns its own Nix packaging, and it can break it — typically by moving a path or a pin in the source without updating its `flake.nix` and `flake.lock` to match. Work through this in order; the ordering matters because the cheap steps often make the expensive one unnecessary.

1. **Read the real error.** `verify` prints the failing `.drv`; `nix-store -l <drv>` has the full log. A build-time network fetch failing on TLS usually means the sandbox has no CA bundle and the derivation was never supposed to reach the network — the fetch itself is the bug, not the TLS error.

2. **Read upstream's own packaging.** `nix flake metadata <input-url> --json` gives the source path in the store; read its `flake.nix` and the scripts the build runs. Compare what the build *expects* against what upstream's flake *provides*. A mismatch between the two, inside upstream's own repo, means this is upstream's bug and not ours.

3. **Check whether upstream already fixed it — before writing anything.**

   ```bash
   gh pr list -R <owner>/<repo> --state open
   gh issue list -R <owner>/<repo> --state open
   ```

   An open PR against a packaging bug is both the diagnosis and the patch, already reviewed by someone who knows the codebase. Also check how far its branch trails `HEAD` (`gh api repos/<owner>/<repo>/compare/<pr-head>...<head>`) — pointing our input straight at the PR branch is tempting but usually costs every commit merged since.

4. **Then choose, with the user.** Reverting the lock, pinning before the breaking commit, and patching locally are all defensible; which one fits depends on how much the user wants the new version. Present the trade-off rather than picking silently.

5. **If patching locally, mirror the upstream fix rather than inventing one**, override in our `flake.nix` (`overrideAttrs`), and leave two things behind: a comment naming the upstream PR and saying to drop the override when it lands, and a memory entry so the removal actually happens. A workaround nobody records becomes permanent.

### Step 5: Wrap up

Summarize what moved, what was already current, and what was deliberately left alone (`pinned` inputs, `channel` bumps the user deferred). Report failures with the actual error, not a paraphrase.

## Script reference

`scripts/packages.py` — run `--help` on any subcommand for exact arguments.

| Subcommand | Purpose | Side effects |
|---|---|---|
| `scan` | List GitHub-sourced packages with metadata | None — pure read |
| `check [--no-flake]` | Packages vs latest release, flake inputs vs upstream head | None — pure read (network, plus one `nix eval`) |
| `prefetch OWNER REPO REV` | Source sha256 for a ref | None — pure read (network) |
| `update-source --file --version --sha256` | Rewrite version + sha256 | Edits file; verifies parse |
| `cargo-hash --file` | Discover the real cargoHash via a controlled build failure | Builds; restores the file before returning |
| `update-cargo --file --cargo-hash` | Rewrite cargoHash | Edits file; verifies parse |
| `verify --attr` | Build a flake attribute, propagating the exit code | Builds |

## Convention notes

- Two `rev` templates live side by side in `packages/`:
  - `rev = "${version}"` — the tag *is* the version (`v20260716`, `1.27.1`)
  - `rev = "v${version}"` — the tag prefixes `v`, the version drops it (`0.34.0` → `v0.34.0`)
  - `derive_version_from_tag` handles both; don't second-guess it
- Version detection tries `gh release view` first, then `gh api .../tags`. `latest_tag_source` in the output says which matched
- Commit messages use `pname`, not the file basename — they coincide today, but the script reads `pname` for a reason
- `check` classifies an input as `app` when its name matches a `packages.<system>` attribute. Adding a new input that ships a binary means also exposing it under `packages` in `flake.nix`, which is what makes it verifiable
