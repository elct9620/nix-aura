#!/usr/bin/env bash
# disk-analyze.sh — macOS 磁碟空間分析與清理建議
# Usage: ./disk-analyze.sh [--clean <category>]

set -euo pipefail

BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
RESET='\033[0m'

# Minimum size (MB) to report
THRESHOLD_MB=500

header() {
  echo ""
  echo -e "${BOLD}${CYAN}=== $1 ===${RESET}"
}

size_mb() {
  local path="$1"
  if [[ -e "$path" ]]; then
    du -sm "$path" 2>/dev/null | awk '{print $1}'
  else
    echo 0
  fi
}

format_size() {
  local mb=$1
  if (( mb >= 1024 )); then
    local gb=$(( mb * 10 / 1024 ))
    local whole=$(( gb / 10 ))
    local frac=$(( gb % 10 ))
    echo "${whole}.${frac}GB"
  else
    echo "${mb}MB"
  fi
}

print_entry() {
  local label="$1" size_mb="$2" cmd="$3"
  if (( size_mb >= THRESHOLD_MB )); then
    echo -e "  ${YELLOW}$(format_size "$size_mb")${RESET}\t${label}"
    echo -e "  ${DIM}clean: ${cmd}${RESET}"
    echo ""
    TOTAL_RECLAIMABLE=$((TOTAL_RECLAIMABLE + size_mb))
  fi
}

clean_caches() {
  for p in "${CACHE_PATHS[@]}"; do
    echo -e "${GREEN}Removing:${RESET} $p"
    rm -rf -- "$p"
  done
}

clean_artifacts() {
  echo -e "${GREEN}Running:${RESET} remove node_modules"
  find ~/Workspace ~/Desktop -name node_modules -type d -maxdepth 5 -exec rm -rf -- {} + 2>/dev/null
  echo -e "${GREEN}Running:${RESET} remove Rust target/"
  find ~/Workspace ~/Desktop -name target -type d -maxdepth 5 -exec rm -rf -- {} + 2>/dev/null
  echo -e "${GREEN}Running:${RESET} remove Python venv"
  find ~/Workspace ~/Desktop \( -name .venv -o -name venv \) -type d -maxdepth 5 -exec rm -rf -- {} + 2>/dev/null
}

clean_category() {
  local category="$1"
  case "$category" in
    nix)
      echo -e "${GREEN}Running:${RESET} nix-env --delete-generations old && nix-collect-garbage -d"
      nix-env --delete-generations old && nix-collect-garbage -d
      ;;
    docker)
      echo -e "${GREEN}Running:${RESET} docker system prune -a --volumes -f"
      docker system prune -a --volumes -f
      ;;
    homebrew)
      echo -e "${GREEN}Running:${RESET} brew cleanup --prune=all"
      brew cleanup --prune=all
      ;;
    caches)
      clean_caches
      ;;
    pkg-cache)
      echo -e "${GREEN}Running:${RESET} clean package manager caches"
      command -v npm &>/dev/null && npm cache clean --force
      command -v yarn &>/dev/null && yarn cache clean
      command -v pnpm &>/dev/null && pnpm store prune
      [[ -d ~/.cargo/registry/cache ]] && rm -rf -- ~/.cargo/registry/cache ~/.cargo/registry/src
      command -v go &>/dev/null && go clean -cache -modcache
      command -v uv &>/dev/null && uv cache clean
      ;;
    ml-models)
      echo "Clean from respective UIs: LM Studio, Hugging Face (huggingface-cli delete-cache)"
      ;;
    artifacts)
      clean_artifacts
      ;;
    runtimes)
      echo "Use: rustup toolchain list && rustup toolchain remove <name>"
      ;;
    *)
      echo "Unknown category: $category"
      ;;
  esac
}

# --- Main ---
TOTAL_RECLAIMABLE=0
CACHE_PATHS=()

echo -e "${BOLD}Disk Usage Analysis — $(date '+%Y-%m-%d %H:%M')${RESET}"
df -h / | tail -1 | while read -r fs size used avail pct rest; do
  echo "Total: ${size}  Used: ${used}  Avail: ${avail}  Use%: ${pct}"
done

# --- Nix Store ---
header "Nix Store"
if [[ -d /nix/store ]]; then
  nix_mb=$(size_mb /nix/store)
  echo -e "  Current size: ${YELLOW}$(format_size "$nix_mb")${RESET}"
  echo -e "  ${DIM}clean: nix-env --delete-generations old && nix-collect-garbage -d${RESET}"
  echo ""
fi

# --- Docker ---
header "Docker"
if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
  docker system df 2>/dev/null | tail -n +2
  echo ""
  echo -e "  ${DIM}clean: docker system prune -a --volumes${RESET}"
  echo ""
else
  echo "  Docker not running, skipping."
fi

# --- Homebrew ---
header "Homebrew"
if command -v brew &>/dev/null; then
  brew_cache_mb=$(size_mb "$(brew --cache)")
  cellar_mb=$(size_mb "$(brew --cellar)")
  echo -e "  Cache: ${YELLOW}$(format_size "$brew_cache_mb")${RESET}"
  echo -e "  Cellar: ${YELLOW}$(format_size "$cellar_mb")${RESET}"
  echo -e "  ${DIM}clean: brew cleanup --prune=all${RESET}"
  echo ""
fi

# --- ~/Library/Caches ---
header "Library Caches"
if [[ -d ~/Library/Caches ]]; then
  while IFS=$'\t' read -r mb path; do
    name=$(basename "$path")
    if (( mb >= THRESHOLD_MB )); then
      echo -e "  ${YELLOW}$(format_size "$mb")${RESET}\t${name}"
      echo -e "  ${DIM}clean: use --clean caches${RESET}"
      echo ""
      TOTAL_RECLAIMABLE=$((TOTAL_RECLAIMABLE + mb))
      CACHE_PATHS+=("$path")
    fi
  done < <(du -sm ~/Library/Caches/* 2>/dev/null | sort -rn)
fi

# --- Package Manager Caches ---
header "Package Manager Caches"

npm_mb=$(size_mb ~/.npm)
print_entry "npm cache (~/.npm)" "$npm_mb" "npm cache clean --force"

yarn_mb=$(size_mb ~/.yarn)
print_entry "yarn cache (~/.yarn)" "$yarn_mb" "yarn cache clean"

pnpm_mb=$(size_mb ~/.pnpm)
print_entry "pnpm store (~/.pnpm)" "$pnpm_mb" "pnpm store prune"

cargo_mb=$(size_mb ~/.cargo/registry)
print_entry "cargo registry (~/.cargo/registry)" "$cargo_mb" "rm -rf ~/.cargo/registry/cache ~/.cargo/registry/src"

go_mb=$(size_mb ~/go)
print_entry "go modules (~/go)" "$go_mb" "go clean -cache -modcache"

uv_mb=$(size_mb ~/.cache/uv)
print_entry "uv cache (~/.cache/uv)" "$uv_mb" "uv cache clean"

go_build_mb=$(size_mb ~/.cache/go-build)
print_entry "go build cache (~/.cache/go-build)" "$go_build_mb" "go clean -cache"

# --- AI/ML Models ---
header "AI/ML Models"

hf_mb=$(size_mb ~/.cache/huggingface)
print_entry "Hugging Face (~/.cache/huggingface)" "$hf_mb" "huggingface-cli delete-cache"

lmstudio_mb=$(size_mb ~/.lmstudio)
print_entry "LM Studio (~/.lmstudio)" "$lmstudio_mb" "echo 'Clean from LM Studio UI: remove unused models'"

omlx_mb=$(size_mb ~/.omlx)
print_entry "OMLX (~/.omlx)" "$omlx_mb" "echo 'Review and remove unused models in ~/.omlx'"

# --- Language Runtimes ---
header "Language Runtimes"

if command -v rbenv &>/dev/null; then
  rbenv_mb=$(size_mb ~/.rbenv)
  echo -e "  Total: ${YELLOW}$(format_size "$rbenv_mb")${RESET}"
  echo -e "  Installed versions:"
  rbenv versions --bare 2>/dev/null | while read -r v; do
    v_mb=$(size_mb ~/.rbenv/versions/"$v")
    echo -e "    ${v}: $(format_size "$v_mb")"
  done
  echo -e "  ${DIM}clean: rbenv uninstall <version>${RESET}"
  echo ""
fi

rustup_mb=$(size_mb ~/.rustup)
print_entry "rustup (~/.rustup)" "$rustup_mb" "rustup toolchain list && echo 'rustup toolchain remove <name>'"

# --- Build Artifacts in Projects ---
header "Build Artifacts (node_modules, target/, .venv)"

echo -e "  ${DIM}Scanning ~/Workspace and ~/Desktop...${RESET}"

scan_artifact() {
  local label="$1"; shift
  local total=0
  while IFS=$'\t' read -r size path; do
    total=$((total + size))
  done < <(find ~/Workspace ~/Desktop "$@" -type d -maxdepth 5 -exec du -sm {} + 2>/dev/null)
  if (( total >= THRESHOLD_MB )); then
    echo -e "  ${YELLOW}$(format_size "$total")${RESET}\t${label}"
    echo ""
    TOTAL_RECLAIMABLE=$((TOTAL_RECLAIMABLE + total))
  fi
}

scan_artifact "node_modules (all)" -name node_modules
scan_artifact "Rust target/ (all)" -name target
scan_artifact "Python venv (all)" \( -name .venv -o -name venv \)
echo -e "  ${DIM}clean: use --clean artifacts${RESET}"

# --- APFS Snapshots ---
header "APFS Snapshots"
tmutil listlocalsnapshots / 2>/dev/null | grep -v "^Snapshots" || echo "  No snapshots found."
echo -e "  ${DIM}Note: Use 'sudo diskutil apfs listSnapshots <disk>' to inspect${RESET}"
echo ""

# --- Summary ---
header "Summary"
df -h / | tail -1 | while read -r fs size used avail pct rest; do
  echo "Current: ${used} used / ${size} total (${avail} available)"
done
echo -e "  Estimated reclaimable: ${RED}$(format_size "$TOTAL_RECLAIMABLE")${RESET} (items >= ${THRESHOLD_MB}MB)"
echo ""
echo -e "  ${DIM}Run with --clean <category> to execute cleanup commands.${RESET}"
echo -e "  ${DIM}Categories: nix, docker, homebrew, caches, pkg-cache, ml-models, artifacts${RESET}"

# --- Clean mode ---
if [[ "${1:-}" == "--clean" ]] && [[ -n "${2:-}" ]]; then
  header "Cleaning: $2"
  clean_category "$2"
  echo ""
  echo -e "${GREEN}Done.${RESET} New disk status:"
  df -h /
fi
