#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"
INSTALL_DIR="${HOME}/.cursor/skills"

usage() {
  cat <<'EOF'
Usage: ./scripts/list.sh

List installable skills in this repository and their installation status.
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
  local max="${2:-80}"
  if (( ${#text} <= max )); then
    printf '%s' "${text}"
  else
    printf '%s...' "${text:0:max-3}"
  fi
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  echo "| Skill | Description | Installed |"
  echo "| --- | --- | --- |"

  local found=0
  local entry base skill_file name description installed
  for entry in "${SKILLS_DIR}"/*; do
    [[ -d "${entry}" ]] || continue
    base="$(basename "${entry}")"
    is_installable_skill_dir "${base}" || continue

    found=1
    skill_file="${entry}/SKILL.md"
    name="${base}"
    description="(missing SKILL.md)"

    if [[ -f "${skill_file}" ]]; then
      name="$(extract_frontmatter_field "${skill_file}" "name" || true)"
      [[ -z "${name}" ]] && name="${base}"
      description="$(extract_frontmatter_field "${skill_file}" "description" || true)"
      [[ -z "${description}" ]] && description="(no description)"
    fi

    if [[ -d "${INSTALL_DIR}/${name}" || -L "${INSTALL_DIR}/${name}" ]]; then
      installed="yes"
    else
      installed="no"
    fi

    description="$(truncate_text "${description}" 80)"
    echo "| ${name} | ${description} | ${installed} |"
  done

  if [[ "${found}" -eq 0 ]]; then
    echo "| _none_ | No installable skills yet. Copy skills/_template/ to get started. | no |"
  fi
}

main "$@"
