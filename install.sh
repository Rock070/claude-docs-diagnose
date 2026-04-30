#!/usr/bin/env bash
# install.sh — install claude-md-best-practices into ~/.claude/skills/

set -euo pipefail

REPO_URL="https://github.com/<your-username>/claude-md-best-practices.git"
SKILL_NAME="claude-md-best-practices"
TARGET_DIR="${HOME}/.claude/skills"

mkdir -p "${TARGET_DIR}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "Cloning ${REPO_URL} ..."
git clone --depth 1 "${REPO_URL}" "${TMP_DIR}/repo"

if [ -d "${TARGET_DIR}/${SKILL_NAME}" ]; then
  echo "Existing ${SKILL_NAME} skill found. Replacing."
  rm -rf "${TARGET_DIR}/${SKILL_NAME}"
fi

cp -r "${TMP_DIR}/repo/${SKILL_NAME}" "${TARGET_DIR}/${SKILL_NAME}"

echo
echo "Installed: ${TARGET_DIR}/${SKILL_NAME}"
echo "Restart Claude Code, then trigger with:  \"Audit my CLAUDE.md.\""
