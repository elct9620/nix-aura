---
name: packages-update
description: Batch-update Nix packages under packages/ in this nix-aura repo to their latest upstream versions. Use this skill whenever the user wants to update, bump, or check for new versions of packages in packages/ (ruby-build, leaf, agent-browser, or any future GitHub-sourced package). Also use when the user says "check for package updates", "bump packages", "update packages", "any new versions?", or asks about a specific package like "update leaf" / "bump ruby-build". Covers both pure source-only packages (mkDerivation with sha256) and Rust packages (also have cargoHash).
---

# Packages Update

Batch helper for updating Nix package files under `packages/` to their latest upstream GitHub releases.

## When to use

- User asks to check whether any package has a new release
- User asks to bump or update one or more packages
- User mentions a specific package in `packages/` and wants it updated

If the user only wants to check (no edits), stop after `check`. If they want to actually update, continue through the update steps.

## How this works

`packages/` contains standalone `.nix` files, each describing one derivation that pulls source from GitHub via `fetchFromGitHub`. Updating a package means:

1. Find the latest release tag upstream
2. Compute the new source `sha256`
3. For Rust packages, also recompute `cargoHash` (vendored crate hash)
4. Rewrite the `.nix` file with the new values
5. Commit per package with a conventional-commit message

A Python helper under `scripts/packages.py` handles parsing, version queries, and file rewriting. The skill orchestrates the steps and decides per-package whether to invoke the Rust path.

## Why a script instead of `nix-update`

`nix-update` is widely used in nixpkgs but is third-party with a large surface (end-to-end version detection + file rewriting + build orchestration in one binary). The script here is intentionally narrow:

- Only handles `fetchFromGitHub` (the only fetcher this repo uses)
- All file-editing logic lives in auditable Python
- Third-party tools we call (`gh`, `nix-prefetch-github`, `nix build`, `nix-instantiate`) each have narrow scope
- Every edit is followed by `nix-instantiate --parse` to catch breakage early

If the repo grows fetchers (`fetchCrate`, `fetchurl`, etc.) or dep-hash kinds (`vendorHash` for Go, `npmDepsHash` for Node), extend `scripts/packages.py` rather than reaching for `nix-update`.

## Workflow

### Step 1: Check for updates

Run the script's `check` subcommand from the repo root:

```bash
python3 .claude/skills/packages-update/scripts/packages.py check
```

This prints JSON with one entry per detected GitHub-sourced package, including `version`, `latest_version`, and `outdated`. Packages without `fetchFromGitHub` (e.g. `aura-pid.nix`) are skipped automatically.

If every `outdated` is `false`, tell the user everything is up to date and stop.

### Step 2: Plan the updates

For each package with `outdated: true`, gather:
- `file` (path to rewrite)
- `owner`, `repo`, `latest_tag` (for prefetching)
- `latest_version` (the value to put back into `version = "..."`)
- Whether `cargo_hash` is non-null (Rust path)

If the user only asked about specific packages, filter to those. Otherwise propose the full list and confirm before making changes.

### Step 3: Update each package

For each package to update, run the steps below in order. Doing one package at a time keeps the commits clean and lets the user bail mid-batch if anything looks off.

**3a. Prefetch the new source sha256:**

```bash
python3 .claude/skills/packages-update/scripts/packages.py prefetch <OWNER> <REPO> <LATEST_TAG>
```

This shells out to `nix-prefetch-github` (via `nix-shell -p`) and prints a single `sha256-...` line.

**3b. Rewrite version + source sha256:**

```bash
python3 .claude/skills/packages-update/scripts/packages.py update-source \
  --file packages/<NAME>.nix \
  --version <LATEST_VERSION> \
  --sha256 <SHA256_FROM_3A>
```

The script replaces both fields uniquely (errors if there are zero or multiple matches) and runs `nix-instantiate --parse` on the file before returning. If parse fails, the script aborts; investigate before continuing.

**3c. Rust only — recompute `cargoHash`:**

Skip this step entirely for packages whose `cargo_hash` was `null` in `check` output.

```bash
python3 .claude/skills/packages-update/scripts/packages.py cargo-hash \
  --file packages/<NAME>.nix
```

This temporarily stages a fake hash, builds the package through the flake (`nix build <flake-root>#<pname>`, deriving the attribute from the file's `pname`), parses the real hash from the build error, restores the file, and prints the real hash. Building via the flake pins the build to the flake's nixpkgs instead of the ambient `<nixpkgs>` system channel, so the hash matches the project's real output. The flake reads the package file from the git working tree, so the staged fake hash is picked up even though it is uncommitted. The build can take minutes the first time as it downloads sources.

Then write it back:

```bash
python3 .claude/skills/packages-update/scripts/packages.py update-cargo \
  --file packages/<NAME>.nix \
  --cargo-hash <HASH_FROM_CARGO_HASH_STEP>
```

**3d. Commit:**

Match the existing convention from `git log` (`chore(<pname>): bump <pname> to <new-version>`):

```bash
git add packages/<NAME>.nix
git commit -m "chore(<pname>): bump <pname> to <latest_version>"
```

Use `<latest_version>` exactly as it appears in the file — for ruby-build that's the `v20260520` form, for leaf it's `1.22.2`, for agent-browser it's `0.27.0`.

### Step 4: Wrap up

Summarize: which packages updated, which were already current, any that failed. If a Rust package failed at `cargo-hash` (e.g. upstream changed the build), surface the error and let the user decide whether to investigate.

## Script reference

`scripts/packages.py` exposes these subcommands. Read `--help` on any of them for the exact arguments.

| Subcommand | Purpose | Side effects |
|---|---|---|
| `scan` | List GitHub-sourced packages with metadata | None — pure read |
| `check` | Same as scan, plus latest upstream tag and `outdated` flag | None — pure read (network) |
| `prefetch OWNER REPO REV` | Compute the source sha256 for a given ref | None — pure read (network) |
| `update-source --file --version --sha256` | Rewrite version + sha256 in a .nix file | Edits file; verifies parse |
| `cargo-hash --file` | Detect the real cargoHash by triggering a controlled flake build failure | Builds source via `nix build <root>#<pname>`; restores file before returning |
| `update-cargo --file --cargo-hash` | Rewrite cargoHash in a .nix file | Edits file; verifies parse |

## Convention notes

- Two `rev` templates live side by side in this repo:
  - `rev = "${version}"` — the tag IS the version string (ruby-build's `v20260520`, leaf's `1.22.2`)
  - `rev = "v${version}"` — the tag prefixes `v`, the version drops it (agent-browser's `0.27.0` → tag `v0.27.0`)
  - The script handles both via `derive_version_from_tag`; don't second-guess it
- The version detection uses `gh release view` first, falling back to `gh api .../tags` if a repo doesn't publish GitHub Releases. The `latest_tag_source` field in `check` output tells you which one matched
- Commit message uses `pname` (kebab-case package name), not file basename — for this repo they happen to match but don't assume
