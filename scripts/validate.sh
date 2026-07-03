#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"

usage() {
  cat <<'EOF'
Usage: ./scripts/validate.sh [skill-name ...]

Validate SKILL.md frontmatter and directory conventions.

With no arguments, validates all installable skills (skips _-prefixed dirs).
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
    echo "ERROR [${skill_name}]: missing SKILL.md"
    return 1
  fi

  if ! head -n 1 "${skill_file}" | grep -q '^---$'; then
    echo "ERROR [${skill_name}]: SKILL.md must start with YAML frontmatter (---)"
    errors=$((errors + 1))
  fi

  local name description line_count
  name="$(extract_frontmatter_field "${skill_file}" "name" || true)"
  description="$(extract_frontmatter_field "${skill_file}" "description" || true)"
  line_count="$(wc -l < "${skill_file}" | tr -d ' ')"

  if [[ -z "${name}" ]]; then
    echo "ERROR [${skill_name}]: frontmatter field 'name' is required"
    errors=$((errors + 1))
  elif [[ ! "${name}" =~ ^[a-z0-9-]+$ ]]; then
    echo "ERROR [${skill_name}]: 'name' must use lowercase letters, numbers, and hyphens only"
    errors=$((errors + 1))
  elif (( ${#name} > 64 )); then
    echo "ERROR [${skill_name}]: 'name' exceeds 64 characters"
    errors=$((errors + 1))
  fi

  if [[ -z "${description}" ]]; then
    echo "ERROR [${skill_name}]: frontmatter field 'description' is required"
    errors=$((errors + 1))
  elif (( ${#description} > 1024 )); then
    echo "ERROR [${skill_name}]: 'description' exceeds 1024 characters"
    errors=$((errors + 1))
  fi

  if [[ -n "${name}" && "${skill_name}" != "${name}" ]]; then
    echo "WARN  [${skill_name}]: directory name '${skill_name}' does not match frontmatter name '${name}'"
    warnings=$((warnings + 1))
  fi

  if (( line_count > 500 )); then
    echo "WARN  [${skill_name}]: SKILL.md has ${line_count} lines (recommended <= 500)"
    warnings=$((warnings + 1))
  fi

  if grep -q '\\' "${skill_file}"; then
    echo "WARN  [${skill_name}]: SKILL.md contains backslashes; use forward slashes for paths"
    warnings=$((warnings + 1))
  fi

  if (( errors > 0 )); then
    return 1
  fi

  echo "OK    [${skill_name}]"
  return 0
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  if [[ ! -d "${SKILLS_DIR}" ]]; then
    echo "ERROR: skills directory not found at ${SKILLS_DIR}"
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
    echo "No installable skills found."
    exit 0
  fi

  local failed=0
  local skill
  for skill in "${targets[@]}"; do
    if [[ "${skill}" == _* ]]; then
      echo "SKIP  [${skill}]: _-prefixed directories are templates, not installable skills"
      continue
    fi
    validate_skill "${skill}" || failed=1
  done

  exit "${failed}"
}

main "$@"
