#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${ROOT_DIR}/skills"
INSTALL_DIR="${HOME}/.cursor/skills"

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [options] [skill-name ...]

Install skills from this repository into ~/.cursor/skills/.

Options:
  --link    Create symlinks instead of copying files
  --force   Overwrite existing installations
  -h, --help  Show this help message

Examples:
  ./scripts/install.sh
  ./scripts/install.sh my-skill-name
  ./scripts/install.sh --link --force my-skill-name
EOF
}

is_installable_skill_dir() {
  local name="$1"
  [[ -d "${SKILLS_DIR}/${name}" ]] || return 1
  [[ "${name}" != _* ]]
}

collect_targets() {
  TARGETS=()
  if ((${#POSITIONAL[@]} > 0)); then
    TARGETS=("${POSITIONAL[@]}")
    return
  fi

  local entry base
  for entry in "${SKILLS_DIR}"/*; do
    [[ -d "${entry}" ]] || continue
    base="$(basename "${entry}")"
    is_installable_skill_dir "${base}" && TARGETS+=("${base}")
  done
}

install_skill() {
  local skill_name="$1"
  local source_dir="${SKILLS_DIR}/${skill_name}"
  local target_dir="${INSTALL_DIR}/${skill_name}"

  if [[ "${skill_name}" == _* ]]; then
    echo "ERROR: '${skill_name}' is a template directory and cannot be installed"
    return 1
  fi

  if [[ ! -d "${source_dir}" ]]; then
    echo "ERROR: skill '${skill_name}' not found in ${SKILLS_DIR}"
    return 1
  fi

  if [[ ! -f "${source_dir}/SKILL.md" ]]; then
    echo "ERROR: '${skill_name}' is missing SKILL.md"
    return 1
  fi

  "${ROOT_DIR}/scripts/validate.sh" "${skill_name}"

  mkdir -p "${INSTALL_DIR}"

  if [[ -e "${target_dir}" || -L "${target_dir}" ]]; then
    if [[ "${FORCE}" != "1" ]]; then
      echo "ERROR: '${target_dir}' already exists (use --force to overwrite)"
      return 1
    fi
    rm -rf "${target_dir}"
  fi

  if [[ "${LINK_MODE}" == "1" ]]; then
    ln -s "${source_dir}" "${target_dir}"
    echo "LINKED ${skill_name} -> ${target_dir}"
  else
    cp -R "${source_dir}" "${target_dir}"
    echo "COPIED ${skill_name} -> ${target_dir}"
  fi
}

main() {
  LINK_MODE=0
  FORCE=0
  POSITIONAL=()

  while (($# > 0)); do
    case "$1" in
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
        echo "ERROR: unknown option '$1'"
        usage
        exit 1
        ;;
      *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
  done

  collect_targets

  if ((${#TARGETS[@]} == 0)); then
    echo "No installable skills found."
    echo "Create one by copying skills/_template/ to skills/your-skill-name/"
    exit 0
  fi

  local failed=0
  local skill
  for skill in "${TARGETS[@]}"; do
    install_skill "${skill}" || failed=1
  done

  exit "${failed}"
}

main "$@"
