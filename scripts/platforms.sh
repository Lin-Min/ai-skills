#!/usr/bin/env bash
# 各 AI 工具的个人技能目录（可通过环境变量覆盖）
# 用法: source scripts/platforms.sh

PLATFORM_IDS="cursor claude codex"

platform_install_dir() {
  case "$1" in
    cursor) echo "${AI_SKILLS_CURSOR_DIR:-${HOME}/.cursor/skills}" ;;
    claude) echo "${AI_SKILLS_CLAUDE_DIR:-${HOME}/.claude/skills}" ;;
    codex) echo "${AI_SKILLS_CODEX_DIR:-${HOME}/.codex/skills}" ;;
    *)
      echo "错误: 未知平台「$1」。支持: ${PLATFORM_IDS}、all" >&2
      return 1
      ;;
  esac
}

platform_label() {
  case "$1" in
    cursor) echo "Cursor" ;;
    claude) echo "Claude Code" ;;
    codex) echo "Codex" ;;
    *) echo "$1" ;;
  esac
}

is_known_platform() {
  case "$1" in
    cursor|claude|codex) return 0 ;;
    *) return 1 ;;
  esac
}

resolve_platform_targets() {
  local input="${1:-all}"
  RESOLVED_PLATFORMS=()

  if [[ "${input}" == "all" ]]; then
    local id
    for id in ${PLATFORM_IDS}; do
      RESOLVED_PLATFORMS+=("${id}")
    done
    return 0
  fi

  local id
  IFS=',' read -ra parts <<< "${input}"
  for id in "${parts[@]}"; do
    id="$(echo "${id}" | tr -d ' ')"
    if ! is_known_platform "${id}"; then
      echo "错误: 未知平台「${id}」。支持: ${PLATFORM_IDS}、all" >&2
      return 1
    fi
    RESOLVED_PLATFORMS+=("${id}")
  done
}

is_skill_installed() {
  local platform="$1"
  local skill_name="$2"
  local dir
  dir="$(platform_install_dir "${platform}")/${skill_name}"
  [[ -d "${dir}" || -L "${dir}" ]]
}
