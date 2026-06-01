#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
SKILLS_SOURCE_DIR="${REPO_ROOT}/skills"

DEFAULT_TARGET="${HOME}/.claude/skills"
ALT_TARGET="${HOME}/.codex/skills"
TARGET="$DEFAULT_TARGET"

log() { printf '%s\n' "$1"; }

ensure_dir() {
  local dir_path="$1"
  if [[ ! -d "$dir_path" ]]; then
    mkdir -p "$dir_path"
    log "created directory: ${dir_path}"
  fi
}

extract_skill_name() {
  local skill_file="$1"
  local name
  name="$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed -n 's/^name:\s*//p')"
  if [[ -z "$name" ]]; then
    name="$(basename "$(dirname "$skill_file")")"
  fi
  printf '%s' "$name"
}

install_skill_copy() {
  local skill_dir="$1"
  local skill_name="$2"
  local source_path
  local target_path

  source_path="$(cd -- "$skill_dir" && pwd -P)"
  target_path="${TARGET}/${skill_name}"

  if [[ -e "$target_path" || -L "$target_path" ]]; then
    rm -rf "$target_path"
    cp -R "$source_path" "$target_path"
    log "skill updated: ${skill_name}"
  else
    cp -R "$source_path" "$target_path"
    log "skill installed: ${skill_name}"
  fi
}

remove_stale_skill_targets() {
  local candidate
  local base_name

  [[ -d "$TARGET" ]] || return

  shopt -s nullglob
  for candidate in "${TARGET}/common-kit-"*; do
    base_name="$(basename "$candidate")"
    local found=0
    local skill_dir
    for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
      [[ -d "$skill_dir" ]] || continue
      local skill_file="${skill_dir}/SKILL.md"
      [[ -f "$skill_file" ]] || continue
      local n
      n="$(extract_skill_name "$skill_file")"
      if [[ "$n" == "$base_name" ]]; then
        found=1
        break
      fi
    done
    if [[ "$found" -eq 0 ]]; then
      rm -rf "$candidate"
      log "stale skill removed: ${base_name}"
    fi
  done
  shopt -u nullglob
}

update_repo() {
  log "updating repository: git pull"
  (
    cd "$REPO_ROOT"
    git pull
  )
  log "repository updated"
}

usage() {
  cat <<EOF
Usage: $0 [--target claude|codex] [--update]

Options:
  --target claude  安装到 ~/.claude/skills/（默认）
  --target codex   安装到 ~/.codex/skills/
  --update         先 git pull 再安装
EOF
  exit 0
}

main() {
  local skill_count=0
  local do_update=0

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
      --update) do_update=1; shift ;;
      -h|--help) usage ;;
      *) echo "error: unknown arg: $1" >&2; exit 1 ;;
    esac
  done

  if [[ "$do_update" -eq 1 ]]; then
    update_repo
  fi

  if [[ ! -d "$SKILLS_SOURCE_DIR" ]]; then
    printf 'error: skills directory not found: %s\n' "$SKILLS_SOURCE_DIR" >&2
    exit 1
  fi

  log "validating skill pack: npm run validate"
  (
    cd "$REPO_ROOT"
    npm run validate
  )

  ensure_dir "$TARGET"
  remove_stale_skill_targets

  shopt -s nullglob
  local skill_dir
  for skill_dir in "$SKILLS_SOURCE_DIR"/*; do
    [[ -d "$skill_dir" ]] || continue
    local skill_file="${skill_dir}/SKILL.md"
    [[ -f "$skill_file" ]] || continue

    local skill_name
    skill_name="$(extract_skill_name "$skill_file")"
    install_skill_copy "$skill_dir" "$skill_name"
    skill_count=$((skill_count + 1))
  done
  shopt -u nullglob

  if [[ "$skill_count" -eq 0 ]]; then
    printf 'error: no skill directories found under skills/\n' >&2
    exit 1
  fi

  cat <<EOF
install complete
- skills synced: ${skill_count}
- target directory: ${TARGET}
- use --update flag next time to git pull before installing
EOF
}

main "$@"
