#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"
# shellcheck source=platforms.sh
source "${ROOT_DIR}/scripts/platforms.sh"

usage() {
  cat <<'EOF'
用法: ./scripts/install.sh [选项] [技能名 ...]

将本仓库中的技能安装到 AI 工具的个人技能目录。

选项:
  --target <平台>  安装目标，逗号分隔；默认 all
                   支持: cursor, claude, codex, all
  --link           创建符号链接，而非复制文件
  --force          覆盖已有安装
  -h, --help       显示此帮助信息

安装路径:
  cursor  -> ~/.cursor/skills/
  claude  -> ~/.claude/skills/
  codex   -> ~/.codex/skills/

示例:
  ./scripts/install.sh
  ./scripts/install.sh --target cursor lighthouse-analysis-optimization
  ./scripts/install.sh --target claude lighthouse-analysis-optimization
  ./scripts/install.sh --target all
EOF
}

is_installable_skill_dir() {
  local name="$1"
  [[ -d "${SKILLS_DIR}/${name}" ]] || return 1
  [[ "${name}" != _* ]]
}

collect_skill_targets() {
  SKILL_TARGETS=()
  if ((${#POSITIONAL[@]} > 0)); then
    SKILL_TARGETS=("${POSITIONAL[@]}")
    return
  fi

  local entry base
  for entry in "${SKILLS_DIR}"/*; do
    [[ -d "${entry}" ]] || continue
    base="$(basename "${entry}")"
    is_installable_skill_dir "${base}" && SKILL_TARGETS+=("${base}")
  done
}

install_skill_to_platform() {
  local skill_name="$1"
  local platform="$2"
  local source_dir="${SKILLS_DIR}/${skill_name}"
  local install_dir
  install_dir="$(platform_install_dir "${platform}")"
  local target_dir="${install_dir}/${skill_name}"
  local label
  label="$(platform_label "${platform}")"

  mkdir -p "${install_dir}"

  if [[ -e "${target_dir}" || -L "${target_dir}" ]]; then
    if [[ "${FORCE}" != "1" ]]; then
      echo "错误 [${label}]: 「${target_dir}」已存在（使用 --force 覆盖）"
      return 1
    fi
    rm -rf "${target_dir}"
  fi

  if [[ "${LINK_MODE}" == "1" ]]; then
    ln -s "${source_dir}" "${target_dir}"
    echo "已链接 [${label}] ${skill_name} -> ${target_dir}"
  else
    cp -R "${source_dir}" "${target_dir}"
    echo "已复制 [${label}] ${skill_name} -> ${target_dir}"
  fi
}

install_skill() {
  local skill_name="$1"
  local source_dir="${SKILLS_DIR}/${skill_name}"

  if [[ "${skill_name}" == _* ]]; then
    echo "错误: 「${skill_name}」为模板目录，不可安装"
    return 1
  fi

  if [[ ! -d "${source_dir}" ]]; then
    echo "错误: 在 ${SKILLS_DIR} 中未找到技能「${skill_name}」"
    return 1
  fi

  if [[ ! -f "${source_dir}/SKILL.md" ]]; then
    echo "错误: 「${skill_name}」缺少 SKILL.md"
    return 1
  fi

  "${ROOT_DIR}/scripts/validate.sh" "${skill_name}"

  local failed=0
  local platform
  for platform in "${RESOLVED_PLATFORMS[@]}"; do
    install_skill_to_platform "${skill_name}" "${platform}" || failed=1
  done

  return "${failed}"
}

main() {
  LINK_MODE=0
  FORCE=0
  TARGET_SPEC="all"
  POSITIONAL=()

  while (($# > 0)); do
    case "$1" in
      --target)
        shift
        [[ $# -gt 0 ]] || { echo "错误: --target 需要参数"; exit 1; }
        TARGET_SPEC="$1"
        shift
        ;;
      --link)
        LINK_MODE=1
        shift
        ;;
      --force)
        FORCE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        POSITIONAL+=("$@")
        break
        ;;
      -*)
        echo "错误: 未知选项「$1」"
        usage
        exit 1
        ;;
      *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
  done

  resolve_platform_targets "${TARGET_SPEC}" || exit 1
  collect_skill_targets

  if ((${#SKILL_TARGETS[@]} == 0)); then
    echo "未找到可安装的技能。"
    echo "可复制 skills/_template/ 到 skills/your-skill-name/ 来创建第一个技能。"
    exit 0
  fi

  local failed=0
  local skill
  for skill in "${SKILL_TARGETS[@]}"; do
    install_skill "${skill}" || failed=1
  done

  exit "${failed}"
}

main "$@"
