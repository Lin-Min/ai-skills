#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"
# shellcheck source=platforms.sh
source "${ROOT_DIR}/scripts/platforms.sh"

usage() {
  cat <<'EOF'
用法: ./scripts/list.sh [选项]

列出本仓库中可安装的技能及各 AI 工具下的安装状态。

选项:
  --target <平台>  只检查指定平台，逗号分隔；默认检查全部
  -h, --help       显示此帮助信息
EOF
}

is_installable_skill_dir() {
  local name="$1"
  [[ -d "${SKILLS_DIR}/${name}" ]] || return 1
  [[ "${name}" != _* ]]
}

extract_frontmatter_field() {
  local file="$1"
  local field="$2"
  awk -v field="${field}" '
    BEGIN { in_fm = 0; value = ""; collecting = 0 }
    NR == 1 && $0 == "---" { in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm {
      if (collecting) {
        if ($0 ~ /^[[:space:]]/) {
          sub(/^[[:space:]]+/, "", $0)
          value = value " " $0
          next
        }
        print value
        exit
      }
      if ($0 ~ ("^" field ":[[:space:]]*>-")) {
        collecting = 1
        next
      }
      if ($0 ~ ("^" field ":[[:space:]]*")) {
        sub("^" field ":[[:space:]]*", "", $0)
        gsub(/^["'\'']|["'\'']$/, "", $0)
        print $0
        exit
      }
    }
  ' "${file}"
}

truncate_text() {
  local text="$1"
  local max="${2:-60}"
  if (( ${#text} <= max )); then
    printf '%s' "${text}"
  else
    printf '%s...' "${text:0:max-3}"
  fi
}

main() {
  local target_spec="all"
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi
  if [[ "${1:-}" == "--target" ]]; then
    shift
    target_spec="${1:-all}"
  fi

  resolve_platform_targets "${target_spec}" || exit 1

  local header="| 技能 | 说明 |"
  local separator="| --- | --- |"
  local platform label
  for platform in "${RESOLVED_PLATFORMS[@]}"; do
    label="$(platform_label "${platform}")"
    header="${header} ${label} |"
    separator="${separator} --- |"
  done
  echo "${header}"
  echo "${separator}"

  local found=0
  local entry base skill_file name description
  for entry in "${SKILLS_DIR}"/*; do
    [[ -d "${entry}" ]] || continue
    base="$(basename "${entry}")"
    is_installable_skill_dir "${base}" || continue

    found=1
    skill_file="${entry}/SKILL.md"
    name="${base}"
    description="（缺少 SKILL.md）"

    if [[ -f "${skill_file}" ]]; then
      name="$(extract_frontmatter_field "${skill_file}" "name" || true)"
      [[ -z "${name}" ]] && name="${base}"
      description="$(extract_frontmatter_field "${skill_file}" "description" || true)"
      [[ -z "${description}" ]] && description="（无描述）"
    fi

    description="$(truncate_text "${description}" 60)"
    local row="| ${name} | ${description} |"
    for platform in "${RESOLVED_PLATFORMS[@]}"; do
      if is_skill_installed "${platform}" "${name}"; then
        row="${row} 是 |"
      else
        row="${row} 否 |"
      fi
    done
    echo "${row}"
  done

  if [[ "${found}" -eq 0 ]]; then
    local empty_row="| _暂无_ | 尚无可安装技能 |"
    for platform in "${RESOLVED_PLATFORMS[@]}"; do
      empty_row="${empty_row} 否 |"
    done
    echo "${empty_row}"
  fi
}

main "$@"
