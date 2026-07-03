#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"

usage() {
  cat <<'EOF'
用法: ./scripts/validate.sh [技能名 ...]

校验 SKILL.md 的 frontmatter 与目录规范。

不传参数时，校验所有可安装技能（跳过以 _ 开头的目录）。
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

validate_skill() {
  local skill_name="$1"
  local skill_dir="${SKILLS_DIR}/${skill_name}"
  local skill_file="${skill_dir}/SKILL.md"
  local errors=0
  local warnings=0

  if [[ ! -f "${skill_file}" ]]; then
    echo "错误 [${skill_name}]: 缺少 SKILL.md"
    return 1
  fi

  if ! head -n 1 "${skill_file}" | grep -q '^---$'; then
    echo "错误 [${skill_name}]: SKILL.md 必须以 YAML frontmatter（---）开头"
    errors=$((errors + 1))
  fi

  local name description line_count
  name="$(extract_frontmatter_field "${skill_file}" "name" || true)"
  description="$(extract_frontmatter_field "${skill_file}" "description" || true)"
  line_count="$(wc -l < "${skill_file}" | tr -d ' ')"

  if [[ -z "${name}" ]]; then
    echo "错误 [${skill_name}]: frontmatter 字段 name 为必填项"
    errors=$((errors + 1))
  elif [[ ! "${name}" =~ ^[a-z0-9-]+$ ]]; then
    echo "错误 [${skill_name}]: name 只能使用小写字母、数字和连字符"
    errors=$((errors + 1))
  elif (( ${#name} > 64 )); then
    echo "错误 [${skill_name}]: name 超过 64 个字符"
    errors=$((errors + 1))
  fi

  if [[ -z "${description}" ]]; then
    echo "错误 [${skill_name}]: frontmatter 字段 description 为必填项"
    errors=$((errors + 1))
  elif (( ${#description} > 1024 )); then
    echo "错误 [${skill_name}]: description 超过 1024 个字符"
    errors=$((errors + 1))
  fi

  if [[ -n "${name}" && "${skill_name}" != "${name}" ]]; then
    echo "警告 [${skill_name}]: 目录名「${skill_name}」与 frontmatter 中的 name「${name}」不一致"
    warnings=$((warnings + 1))
  fi

  if (( line_count > 500 )); then
    echo "警告 [${skill_name}]: SKILL.md 共 ${line_count} 行（建议不超过 500 行）"
    warnings=$((warnings + 1))
  fi

  if grep -q '\\' "${skill_file}"; then
    echo "警告 [${skill_name}]: SKILL.md 包含反斜杠，路径请使用正斜杠"
    warnings=$((warnings + 1))
  fi

  if (( errors > 0 )); then
    return 1
  fi

  echo "通过 [${skill_name}]"
  return 0
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "错误: 未找到 skills 目录 ${SKILLS_DIR}"
    exit 1
  fi

  local targets=()
  if (($# > 0)); then
    targets=("$@")
  else
    local entry
    for entry in "${SKILLS_DIR}"/*; do
      [[ -d "${entry}" ]] || continue
      local base
      base="$(basename "${entry}")"
      is_installable_skill_dir "${base}" && targets+=("${base}")
    done
  fi

  if ((${#targets[@]} == 0)); then
    echo "未找到可安装的技能。"
    exit 0
  fi

  local failed=0
  local skill
  for skill in "${targets[@]}"; do
    if [[ "${skill}" == _* ]]; then
      echo "跳过 [${skill}]: 以 _ 开头的目录为模板，不可安装"
      continue
    fi
    validate_skill "${skill}" || failed=1
  done

  exit "${failed}"
}

main "$@"
