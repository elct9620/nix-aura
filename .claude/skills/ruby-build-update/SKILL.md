---
name: ruby-build-update
description: Update the ruby-build package in this nix-aura repository to the latest version. Use this skill whenever the user wants to update ruby-build, bump ruby-build, check for new ruby-build releases, or mentions updating Nix packages related to Ruby. Also use when the user says things like "update ruby", "new ruby-build version", or "bump packages".
---

# Ruby-Build Update

Update the ruby-build Nix package to the latest release from GitHub.

## Why this skill exists

The `packages/ruby-build.nix` file pins a specific version and sha256 hash of rbenv/ruby-build from GitHub. Updating it requires fetching the latest release tag, computing the Nix-compatible hash, and editing two fields in the file. This skill automates that entire flow.

## Workflow

### Step 1: Get the latest release version

Use `gh` to fetch the latest release tag from rbenv/ruby-build:

```bash
gh release view --repo rbenv/ruby-build --json tagName -q '.tagName'
```

### Step 2: Read the current version

Read `packages/ruby-build.nix` and extract the current `version` value. If the latest release matches the current version, inform the user that ruby-build is already up to date and stop.

### Step 3: Compute the new sha256 hash

Use `nix-shell` with `nix-prefetch-github` and `jq` to compute the hash for the new version:

```bash
nix-shell -p nix-prefetch-github jq --run "nix-prefetch-github rbenv ruby-build --quiet --rev <VERSION> | jq -r '.hash'"
```

Replace `<VERSION>` with the tag from Step 1 (e.g., `v20260326`).

This command may take a few seconds. The output is a string like `sha256-XXXX...`.

### Step 4: Update packages/ruby-build.nix

Edit `packages/ruby-build.nix` to update exactly two fields:
- `version` — change to the new release tag (e.g., `"v20260401"`)
- `sha256` — change to the newly computed hash

Do not modify any other part of the file.

### Step 5: Commit

Create a commit with the message format:

```
chore(ruby-build): bump ruby-build to <VERSION>
```

This follows the repository's established conventional commit pattern (check `git log` to confirm).
