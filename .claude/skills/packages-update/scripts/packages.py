#!/usr/bin/env python3
"""Batch helper for updating Nix packages under packages/.

Subcommands:
  scan            List packages with extractable metadata.
  check           Compare scanned packages against the latest GitHub release.
  prefetch        Compute the source sha256 for a given owner/repo/rev.
  update-source   Rewrite a package's version and source sha256.
  cargo-hash      Run nix-build to discover the real cargoHash.
  update-cargo    Rewrite a package's cargoHash.

Output is JSON wherever a structured result is useful; the skill orchestrator
parses it. Errors are written to stderr and the process exits non-zero so the
caller can react.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

PNAME_RE = re.compile(r'pname\s*=\s*"([^"]+)"')
VERSION_RE = re.compile(r'version\s*=\s*"([^"]+)"')
FETCH_MARKER_RE = re.compile(r"fetchFromGitHub")
OWNER_RE = re.compile(r'owner\s*=\s*"([^"]+)"')
REPO_RE = re.compile(r'repo\s*=\s*"([^"]+)"')
REV_RE = re.compile(r'rev\s*=\s*"([^"]+)"')
SRC_SHA_RE = re.compile(r'sha256\s*=\s*"([^"]+)"')
CARGO_HASH_RE = re.compile(r'cargoHash\s*=\s*"([^"]+)"')
GOT_HASH_RE = re.compile(r"got:\s*(sha256-[A-Za-z0-9+/=]+)")


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def parse_package(path: Path) -> dict | None:
    """Return metadata for a .nix file or None if it has no GitHub source.

    Each field (owner/repo/rev/sha256) appears at most once per package file in
    this repo's convention, so scanning the whole file is unambiguous and side-
    steps trying to balance braces around `${version}` interpolations.
    """
    content = path.read_text()

    if not FETCH_MARKER_RE.search(content):
        return None

    owner = OWNER_RE.search(content)
    repo = REPO_RE.search(content)
    rev = REV_RE.search(content)
    src_sha = SRC_SHA_RE.search(content)
    pname = PNAME_RE.search(content)
    version = VERSION_RE.search(content)

    if owner is None or repo is None or rev is None or src_sha is None:
        return None
    if pname is None or version is None:
        return None

    cargo = CARGO_HASH_RE.search(content)
    return {
        "file": str(path),
        "pname": pname.group(1),
        "version": version.group(1),
        "owner": owner.group(1),
        "repo": repo.group(1),
        "rev_template": rev.group(1),
        "sha256": src_sha.group(1),
        "cargo_hash": cargo.group(1) if cargo is not None else None,
    }


def derive_version_from_tag(tag: str, rev_template: str) -> str:
    """Map a GitHub tag back to the value that should live in `version = "..."`.

    Two conventions live side by side in packages/:
      rev = "${version}"   -> the tag IS the version string (e.g. v20260520)
      rev = "v${version}"  -> the tag prefixes v, version drops it (e.g. 0.27.0)
    """
    if rev_template == "v${version}":
        return tag[1:] if tag.startswith("v") else tag
    return tag


def cmd_scan(args: argparse.Namespace) -> int:
    base = Path(args.packages_dir)
    if not base.is_dir():
        print(f"packages dir not found: {base}", file=sys.stderr)
        return 1

    results = []
    skipped = []
    for path in sorted(base.glob("*.nix")):
        meta = parse_package(path)
        if meta is None:
            skipped.append(str(path))
        else:
            results.append(meta)

    json.dump({"packages": results, "skipped": skipped}, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


def latest_release_tag(owner: str, repo: str) -> tuple[str, str] | None:
    """Return (tag, source) — source is 'release' or 'tag'.

    Falls back to the latest git tag when a repo doesn't publish GitHub
    Releases (some upstreams tag but never cut a release object).
    """
    proc = run(
        [
            "gh",
            "release",
            "view",
            "--repo",
            f"{owner}/{repo}",
            "--json",
            "tagName",
            "-q",
            ".tagName",
        ]
    )
    if proc.returncode == 0 and proc.stdout.strip():
        return proc.stdout.strip(), "release"

    proc = run(
        [
            "gh",
            "api",
            f"repos/{owner}/{repo}/tags",
            "--jq",
            ".[0].name",
        ]
    )
    if proc.returncode == 0 and proc.stdout.strip() and proc.stdout.strip() != "null":
        return proc.stdout.strip(), "tag"

    return None


def cmd_check(args: argparse.Namespace) -> int:
    base = Path(args.packages_dir)
    rows = []
    for path in sorted(base.glob("*.nix")):
        meta = parse_package(path)
        if meta is None:
            continue

        result = latest_release_tag(meta["owner"], meta["repo"])
        if result is None:
            rows.append(
                {
                    **meta,
                    "latest_tag": None,
                    "latest_version": None,
                    "outdated": None,
                    "error": "no release or tag found via gh",
                }
            )
            continue

        tag, source = result
        latest_version = derive_version_from_tag(tag, meta["rev_template"])
        rows.append(
            {
                **meta,
                "latest_tag": tag,
                "latest_tag_source": source,
                "latest_version": latest_version,
                "outdated": latest_version != meta["version"],
            }
        )

    json.dump({"packages": rows}, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


def cmd_prefetch(args: argparse.Namespace) -> int:
    cmd = (
        f"nix-prefetch-github {args.owner} {args.repo} "
        f"--quiet --rev {args.rev} | jq -r '.hash'"
    )
    proc = run(["nix-shell", "-p", "nix-prefetch-github", "jq", "--run", cmd])
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return proc.returncode
    sys.stdout.write(proc.stdout.strip() + "\n")
    return 0


def replace_unique(content: str, pattern: re.Pattern[str], replacement: str, label: str) -> str:
    matches = list(pattern.finditer(content))
    if not matches:
        raise SystemExit(f"could not find {label}")
    if len(matches) > 1:
        raise SystemExit(f"ambiguous {label}: found {len(matches)} matches")
    m = matches[0]
    return content[: m.start()] + replacement + content[m.end() :]


def verify_parses(path: Path) -> None:
    """Sanity-check that the edited .nix file still parses.

    Cheap insurance against regex edits that accidentally produce invalid Nix;
    nix-instantiate --parse only lexes/parses, it doesn't evaluate or build.
    """
    proc = run(["nix-instantiate", "--parse", str(path)])
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        raise SystemExit(f"{path} no longer parses after edit; aborting")


def cmd_update_source(args: argparse.Namespace) -> int:
    path = Path(args.file)
    content = path.read_text()

    content = replace_unique(
        content,
        re.compile(r'version\s*=\s*"[^"]+"'),
        f'version = "{args.version}"',
        "version field",
    )
    content = replace_unique(
        content,
        re.compile(r'sha256\s*=\s*"[^"]+"'),
        f'sha256 = "{args.sha256}"',
        "source sha256",
    )

    path.write_text(content)
    verify_parses(path)
    print(f"updated {path}: version={args.version}")
    return 0


def cmd_cargo_hash(args: argparse.Namespace) -> int:
    """Stage a fake cargoHash, build the package, parse the real one from stderr."""
    path = Path(args.file)
    content = path.read_text()

    if not CARGO_HASH_RE.search(content):
        print(f"{path} has no cargoHash; skipping", file=sys.stderr)
        return 0

    original = content
    staged = replace_unique(
        content,
        re.compile(r'cargoHash\s*=\s*"[^"]+"'),
        f'cargoHash = "{FAKE_HASH}"',
        "cargoHash",
    )
    path.write_text(staged)

    try:
        proc = run(["nix-build", str(path), "--no-out-link"])
        combined = proc.stdout + proc.stderr
        # The hash mismatch can be reported multiple times; the cargo deps one
        # is the only one that follows the staged fake hash. We just take the
        # last 'got:' line that doesn't echo back the fake hash itself.
        candidates = [
            h
            for h in GOT_HASH_RE.findall(combined)
            if h != FAKE_HASH
        ]
        if not candidates:
            sys.stderr.write(combined)
            return 1
        real_hash = candidates[-1]
        print(real_hash)
        return 0
    finally:
        path.write_text(original)


def cmd_update_cargo(args: argparse.Namespace) -> int:
    path = Path(args.file)
    content = path.read_text()
    content = replace_unique(
        content,
        re.compile(r'cargoHash\s*=\s*"[^"]+"'),
        f'cargoHash = "{args.cargo_hash}"',
        "cargoHash",
    )
    path.write_text(content)
    verify_parses(path)
    print(f"updated cargoHash in {path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_scan = sub.add_parser("scan", help="list packages")
    p_scan.add_argument("--packages-dir", default="packages")
    p_scan.set_defaults(func=cmd_scan)

    p_check = sub.add_parser("check", help="check for updates against GitHub releases")
    p_check.add_argument("--packages-dir", default="packages")
    p_check.set_defaults(func=cmd_check)

    p_pref = sub.add_parser("prefetch", help="compute source sha256")
    p_pref.add_argument("owner")
    p_pref.add_argument("repo")
    p_pref.add_argument("rev")
    p_pref.set_defaults(func=cmd_prefetch)

    p_us = sub.add_parser("update-source", help="rewrite version + source sha256")
    p_us.add_argument("--file", required=True)
    p_us.add_argument("--version", required=True)
    p_us.add_argument("--sha256", required=True)
    p_us.set_defaults(func=cmd_update_source)

    p_ch = sub.add_parser("cargo-hash", help="detect cargoHash by building")
    p_ch.add_argument("--file", required=True)
    p_ch.set_defaults(func=cmd_cargo_hash)

    p_uc = sub.add_parser("update-cargo", help="rewrite cargoHash")
    p_uc.add_argument("--file", required=True)
    p_uc.add_argument("--cargo-hash", required=True)
    p_uc.set_defaults(func=cmd_update_cargo)

    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
