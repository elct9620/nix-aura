#!/usr/bin/env python3
"""Batch helper for updating this repo's Nix dependencies.

Two kinds of dependency live here and both go stale:
  - packages/*.nix   derivations pinning a GitHub tag via fetchFromGitHub
  - flake inputs     other flakes pinned by rev in flake.lock

Subcommands:
  scan            List packages with extractable metadata.
  check           Compare packages against releases and flake inputs against
                  their upstream branch heads.
  prefetch        Compute the source sha256 for a given owner/repo/rev.
  update-source   Rewrite a package's version and source sha256.
  cargo-hash      Build the package via the flake to discover the real cargoHash.
  update-cargo    Rewrite a package's cargoHash.
  verify          Build a flake attribute and propagate the real exit code.

Output is JSON wherever a structured result is useful; the skill orchestrator
parses it. Errors are written to stderr and the process exits non-zero so the
caller can react.
"""

from __future__ import annotations

import argparse
import json
import re
import signal
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

FAKE_HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

PNAME_RE = re.compile(r'pname\s*=\s*"([^"]+)"')
VERSION_RE = re.compile(r'version\s*=\s*"([^"]+)"')
FETCH_MARKER_RE = re.compile(r"fetchFromGitHub")
OWNER_RE = re.compile(r'owner\s*=\s*"([^"]+)"')
REPO_RE = re.compile(r'repo\s*=\s*"([^"]+)"')
REV_RE = re.compile(r'rev\s*=\s*"([^"]+)"')
SRC_HASH_RE = re.compile(r'(hash|sha256)\s*=\s*"([^"]+)"')
SRC_BLOCK_RE = re.compile(r"src\s*=\s*fetchFromGitHub\s*\{")
VERSION_ASSIGN_RE = re.compile(r'version\s*=\s*"[^"]+"')
CARGO_HASH_RE = re.compile(r'cargoHash\s*=\s*"([^"]+)"')
GOT_HASH_RE = re.compile(r"got:\s*(sha256-[A-Za-z0-9+/=]+)")


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, **kwargs)


def stream_until_match(
    cmd: list[str],
    matcher: "re.Pattern[str]",
    skip: set[str] | None = None,
) -> tuple[str | None, str]:
    """Run cmd streaming live, return as soon as a line satisfies matcher.

    Returns (first_match_group1, captured_text). On match we terminate the
    process immediately rather than wait for natural exit — this matters
    because nix-build often hangs in its post-FOD-failure daemon protocol
    cleanup on macOS, even though the hash we need has already been printed.
    """
    skip = skip or set()
    proc = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    captured: list[str] = []
    matched: str | None = None
    assert proc.stdout is not None
    try:
        for line in proc.stdout:
            sys.stderr.write(line)
            sys.stderr.flush()
            captured.append(line)
            m = matcher.search(line)
            if m and m.group(1) not in skip:
                matched = m.group(1)
                break
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
    return matched, "".join(captured)


def install_term_handler() -> None:
    """Convert SIGTERM into SystemExit so try/finally blocks still run.

    Without this, a bash-level timeout or `kill` would skip the finally
    that restores files staged with a fake hash.
    """
    def _handler(signum, _frame):
        raise SystemExit(f"received signal {signum}")

    signal.signal(signal.SIGTERM, _handler)


def brace_span(content: str, open_index: int) -> tuple[int, int]:
    """Span of the attribute set opening at `open_index`, braces excluded.

    Nix interpolates with `${...}`, whose braces belong to the string rather
    than to the set, so they are skipped rather than counted.
    """
    depth = 0
    i = open_index
    while i < len(content):
        if content[i] == "$" and content[i + 1 : i + 2] == "{":
            inner = 1
            i += 2
            while i < len(content) and inner:
                inner += (content[i] == "{") - (content[i] == "}")
                i += 1
            continue
        if content[i] == "{":
            depth += 1
        elif content[i] == "}":
            depth -= 1
            if depth == 0:
                return open_index + 1, i
        i += 1
    raise SystemExit(f"unbalanced braces starting at offset {open_index}")


def src_block_span(content: str) -> tuple[int, int] | None:
    """Span of the `src = fetchFromGitHub { ... }` the package is built from.

    A file may carry several such fetches -- vendored sources a build cannot
    reach the network for, or a dependency built alongside -- so the last one
    is taken: nixpkgs convention puts the derivation being packaged after
    whatever it is assembled from.
    """
    matches = list(SRC_BLOCK_RE.finditer(content))
    if not matches:
        return None
    return brace_span(content, matches[-1].end() - 1)


def parse_package(path: Path) -> dict | None:
    """Return metadata for a .nix file or None if it has no GitHub source.

    Everything describing the source is read from the `src` block itself, and
    the identity from the last `pname`/`version` declared ahead of it, so a
    file carrying more than one derivation is read as the one it packages.
    """
    content = path.read_text()

    if not FETCH_MARKER_RE.search(content):
        return None

    span = src_block_span(content)
    if span is None:
        return None
    block = content[span[0] : span[1]]

    owner = OWNER_RE.search(block)
    repo = REPO_RE.search(block)
    rev = REV_RE.search(block)
    src_hash = SRC_HASH_RE.search(block)
    pname = last_before(PNAME_RE, content, span[0])
    version = last_before(VERSION_RE, content, span[0])

    if owner is None or repo is None or rev is None or src_hash is None:
        return None
    if pname is None or version is None:
        return None

    cargo = CARGO_HASH_RE.search(content)
    return {
        "file": str(path),
        "pname": pname,
        "version": version,
        "owner": owner.group(1),
        "repo": repo.group(1),
        "rev_template": rev.group(1),
        "sha256": src_hash.group(2),
        "cargo_hash": cargo.group(1) if cargo is not None else None,
    }


def last_before(pattern: re.Pattern[str], content: str, limit: int) -> str | None:
    """The last capture of `pattern` occurring before `limit`."""
    found = [m.group(1) for m in pattern.finditer(content) if m.start() < limit]
    return found[-1] if found else None


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


def iso_date(timestamp: int | None) -> str | None:
    if timestamp is None:
        return None
    return datetime.fromtimestamp(timestamp, timezone.utc).date().isoformat()


def flake_package_attrs(flake_root: Path) -> set[str]:
    """Names under `packages.<system>` in the flake.

    An input whose name matches one of these is something we build and ship, so
    `verify` has a concrete attribute to check after bumping it. Inputs that
    match nothing (libraries like flake-utils) have no build of their own.
    """
    system = run(
        ["nix", "eval", "--impure", "--raw", "--expr", "builtins.currentSystem",
         "--extra-experimental-features", "nix-command flakes"]
    )
    if system.returncode != 0:
        return set()

    proc = run(
        ["nix", "eval", f"{flake_root}#packages.{system.stdout.strip()}",
         "--apply", "builtins.attrNames", "--json",
         "--extra-experimental-features", "nix-command flakes"]
    )
    if proc.returncode != 0:
        return set()
    try:
        return set(json.loads(proc.stdout))
    except json.JSONDecodeError:
        return set()


def upstream_head(owner: str, repo: str, ref: str | None) -> tuple[str, str] | None:
    """Return (sha, iso_date) for a branch head, or the default branch's."""
    if ref is None:
        proc = run(["gh", "api", f"repos/{owner}/{repo}", "--jq", ".default_branch"])
        if proc.returncode != 0 or not proc.stdout.strip():
            return None
        ref = proc.stdout.strip()

    proc = run(
        ["gh", "api", f"repos/{owner}/{repo}/commits/{ref}",
         "--jq", "[.sha, .commit.committer.date] | @tsv"]
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    parts = proc.stdout.strip().split("\t")
    if len(parts) != 2:
        return None
    return parts[0], parts[1][:10]


def commits_behind(owner: str, repo: str, base: str, head: str) -> int | None:
    """How many commits the locked rev trails the branch head by.

    Best-effort: GitHub declines to compare refs that have diverged enormously
    (a months-old nixpkgs pin, say), and a missing count is not a reason to
    withhold the rest of the row — `outdated` already stands on the rev diff.
    """
    proc = run(
        ["gh", "api", f"repos/{owner}/{repo}/compare/{base}...{head}",
         "--jq", ".ahead_by"]
    )
    if proc.returncode != 0 or not proc.stdout.strip():
        return None
    try:
        return int(proc.stdout.strip())
    except ValueError:
        return None


def check_flake_inputs(flake_root: Path) -> list[dict]:
    """Compare each direct flake input in flake.lock against its upstream.

    Only the root node's own inputs are examined. Transitive inputs belong to
    the flake that declares them; bumping one here would override a pin its
    owner chose, which is a different decision from keeping our own current.
    """
    lock_path = flake_root / "flake.lock"
    if not lock_path.is_file():
        return []

    lock = json.loads(lock_path.read_text())
    nodes = lock.get("nodes", {})
    root_inputs = nodes.get("root", {}).get("inputs", {})
    attrs = flake_package_attrs(flake_root)

    rows = []
    for name, node_key in sorted(root_inputs.items()):
        if not isinstance(node_key, str):
            # A list means `follows`; it has no pin of its own to compare.
            continue
        node = nodes.get(node_key, {})
        locked = node.get("locked", {})
        original = node.get("original", {})

        row = {
            "input": name,
            "locked_rev": locked.get("rev"),
            "locked_date": iso_date(locked.get("lastModified")),
            "ref": original.get("ref"),
            "package_attr": name if name in attrs else None,
        }

        if original.get("rev") is not None:
            rows.append({
                **row,
                "kind": "pinned",
                "outdated": False,
                "note": "rev pinned in flake.nix; updating it is a deliberate "
                        "change, not a routine bump",
            })
            continue

        if locked.get("type") != "github":
            rows.append({
                **row,
                "kind": "unsupported",
                "outdated": None,
                "note": f"locked type {locked.get('type')!r} is not github; "
                        "check this input by hand",
            })
            continue

        owner, repo = locked.get("owner"), locked.get("repo")
        if owner == "NixOS" and repo == "nixpkgs":
            kind = "channel"
        elif row["package_attr"] is not None:
            kind = "app"
        else:
            kind = "flake"

        head = upstream_head(owner, repo, original.get("ref"))
        if head is None:
            rows.append({
                **row,
                "kind": kind,
                "outdated": None,
                "error": "could not resolve upstream head via gh",
            })
            continue

        upstream_rev, upstream_date = head
        outdated = upstream_rev != row["locked_rev"]
        rows.append({
            **row,
            "kind": kind,
            "owner": owner,
            "repo": repo,
            "upstream_rev": upstream_rev,
            "upstream_date": upstream_date,
            "outdated": outdated,
            "behind_by": (
                commits_behind(owner, repo, row["locked_rev"], upstream_rev)
                if outdated and row["locked_rev"] else None
            ),
        })

    return rows


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

    out: dict = {"packages": rows}
    if not args.no_flake:
        flake_root = find_flake_root(base if base.is_dir() else Path.cwd())
        if flake_root is None:
            out["flake_inputs_error"] = "no flake.nix found; skipped flake inputs"
        else:
            out["flake_inputs"] = check_flake_inputs(flake_root)

    json.dump(out, sys.stdout, indent=2)
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


def replace_unique(
    content: str,
    pattern: re.Pattern[str],
    replacement: str | None,
    label: str,
    render=None,
) -> str:
    matches = list(pattern.finditer(content))
    if not matches:
        raise SystemExit(f"could not find {label}")
    if len(matches) > 1:
        raise SystemExit(f"ambiguous {label}: found {len(matches)} matches")
    m = matches[0]
    text = render(m) if render is not None else replacement
    return content[: m.start()] + text + content[m.end() :]


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

    # The `src` block decides which derivation is being updated, so both edits
    # are made against it: the version is the last one declared ahead of it,
    # the same one `scan` reads back.
    span = src_block_span(content)
    if span is None:
        raise SystemExit("could not find a src = fetchFromGitHub block")

    versions = [m for m in VERSION_ASSIGN_RE.finditer(content) if m.start() < span[0]]
    if not versions:
        raise SystemExit("could not find version field")
    m = versions[-1]
    content = content[: m.start()] + f'version = "{args.version}"' + content[m.end() :]
    # The hash is rewritten inside the `src` block alone: a file carrying
    # vendored sources has several, and under whichever of the two attribute
    # names it already uses. The span is taken again -- the edit above moved it.
    span = src_block_span(content)
    block = replace_unique(
        content[span[0] : span[1]],
        SRC_HASH_RE,
        None,
        "source hash",
        lambda m: f'{m.group(1)} = "{args.sha256}"',
    )
    content = content[: span[0]] + block + content[span[1] :]

    path.write_text(content)
    verify_parses(path)
    print(f"updated {path}: version={args.version}")
    return 0


def find_flake_root(start: Path) -> Path | None:
    """Walk up from start until a directory containing flake.nix is found.

    cargoHash is computed by building the package through the flake (not a
    standalone ``nix-build`` of the .nix file) so the build uses the flake's
    pinned nixpkgs rather than the ambient ``<nixpkgs>`` system channel.
    """
    for directory in [start.resolve(), *start.resolve().parents]:
        if (directory / "flake.nix").is_file():
            return directory
    return None


def cmd_cargo_hash(args: argparse.Namespace) -> int:
    """Stage a fake cargoHash, build the package, parse the real one from stderr.

    The build runs through the flake (``nix build <root>#<pname>``) so the
    cargoHash matches what the flake's pinned nixpkgs produces. The flake reads
    the package file from the git working tree, so staging the fake hash in the
    file is picked up even though it is uncommitted.

    The build can be long-running on a cold cache (rustc download + every
    crate from crates.io). Output is streamed live so the caller can see
    progress; without that, buffering looks indistinguishable from a hang.
    """
    install_term_handler()

    path = Path(args.file)
    content = path.read_text()

    if not CARGO_HASH_RE.search(content):
        print(f"{path} has no cargoHash; skipping", file=sys.stderr)
        return 0

    pname_match = PNAME_RE.search(content)
    if pname_match is None:
        sys.stderr.write(f"{path} has no pname; cannot resolve flake attribute\n")
        return 1
    pname = pname_match.group(1)

    flake_root = find_flake_root(path)
    if flake_root is None:
        sys.stderr.write(f"no flake.nix found above {path}\n")
        return 1

    original = content
    staged = replace_unique(
        content,
        re.compile(r'cargoHash\s*=\s*"[^"]+"'),
        f'cargoHash = "{FAKE_HASH}"',
        "cargoHash",
    )
    path.write_text(staged)

    try:
        real_hash, _ = stream_until_match(
            [
                "nix", "build", f"{flake_root}#{pname}",
                "--no-link", "--no-write-lock-file",
                "--extra-experimental-features", "nix-command flakes",
            ],
            GOT_HASH_RE,
            skip={FAKE_HASH},
        )
        if real_hash is None:
            sys.stderr.write("no cargoHash mismatch found in build output\n")
            return 1
        # Print to stdout so the orchestrator can capture it cleanly; the
        # build chatter went to stderr and is already on screen.
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


def cmd_verify(args: argparse.Namespace) -> int:
    """Build a flake attribute and hand back nix's own exit code.

    A bumped pin that evaluates is not a bumped pin that builds: upstream can
    change its build in ways only a real build surfaces. This exists because
    piping `nix build` into `tail`/`head` reports the pipe's success, so a
    failed build reads as a passing one — the wrapper removes that footgun and
    points at the full log, which holds the actual error.
    """
    flake_root = find_flake_root(Path(args.flake_root or "."))
    if flake_root is None:
        sys.stderr.write("no flake.nix found\n")
        return 1

    proc = subprocess.run(
        ["nix", "build", f"{flake_root}#{args.attr}", "--no-link",
         "--extra-experimental-features", "nix-command flakes"],
        stderr=subprocess.PIPE, text=True,
    )
    sys.stderr.write(proc.stderr)

    if proc.returncode == 0:
        print(f"ok: {args.attr} builds")
        return 0

    drv = re.search(r"(/nix/store/\S+\.drv)", proc.stderr)
    sys.stderr.write(f"\nbuild of {args.attr} failed (exit {proc.returncode})\n")
    if drv:
        sys.stderr.write(f"full log: nix-store -l {drv.group(1)}\n")
    return proc.returncode


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_scan = sub.add_parser("scan", help="list packages")
    p_scan.add_argument("--packages-dir", default="packages")
    p_scan.set_defaults(func=cmd_scan)

    p_check = sub.add_parser(
        "check", help="check packages against releases and flake inputs against upstream"
    )
    p_check.add_argument("--packages-dir", default="packages")
    p_check.add_argument(
        "--no-flake", action="store_true", help="skip the flake input comparison"
    )
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

    p_v = sub.add_parser("verify", help="build a flake attribute, propagating exit code")
    p_v.add_argument("--attr", required=True)
    p_v.add_argument("--flake-root", default=None)
    p_v.set_defaults(func=cmd_verify)

    return parser


def main() -> int:
    args = build_parser().parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
