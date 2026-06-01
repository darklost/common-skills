#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
MANIFEST="${REPO_ROOT}/common-skills.manifest.json"

DEFAULT_TARGET="${HOME}/.claude/skills"
ALT_TARGET="${HOME}/.codex/skills"
TARGET="$DEFAULT_TARGET"

log() { printf '%s\n' "$1"; }

usage() {
  cat <<EOF
Usage: $0 [--target claude|codex]

Options:
  --target claude  从 ~/.claude/skills/ 卸载（默认）
  --target codex   从 ~/.codex/skills/ 卸载
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      case "${2:-}" in
        claude) TARGET="$DEFAULT_TARGET" ;;
        codex)  TARGET="$ALT_TARGET" ;;
        *)      echo "error: unknown target: ${2:-}" >&2; exit 1 ;;
      esac
      shift 2
      ;;
    -h|--help) usage ;;
    *) echo "error: unknown arg: $1" >&2; exit 1 ;;
  esac
done

main() {
  local skill_count=0
  local name

  while IFS= read -r name; do
    local target_path="${TARGET}/${name}"

    if [[ -d "$target_path" || -L "$target_path" ]]; then
      rm -rf "$target_path"
      log "removed: ${name}"
      skill_count=$((skill_count + 1))
    fi
  done < <(node -e "
const m = JSON.parse(require('fs').readFileSync('${MANIFEST}','utf-8'));
m.skills.forEach(s => console.log(s.name));
")

  log "uninstall complete: ${skill_count} skills removed from ${TARGET}"
}

main
