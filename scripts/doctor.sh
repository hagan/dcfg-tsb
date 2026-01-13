#!/usr/bin/env bash
# Validate dcfg-tsb environment and configuration
# Run this after setup to check for issues

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
NC="\033[0m"

ERRORS=0
WARNINGS=0

check_pass() {
  printf '%b[pass]%b %s\n' "$GREEN" "$NC" "$1"
}

check_warn() {
  printf '%b[warn]%b %s\n' "$YELLOW" "$NC" "$1"
  WARNINGS=$((WARNINGS + 1))
}

check_fail() {
  printf '%b[fail]%b %s\n' "$RED" "$NC" "$1"
  ERRORS=$((ERRORS + 1))
}

printf '%b=== dcfg-tsb Doctor ===%b\n\n' "$CYAN" "$NC"

# ============================================================
# Repository Structure
# ============================================================
printf '%b--- Repository Structure ---%b\n' "$CYAN" "$NC"

if [ -d "$REPO_ROOT" ]; then
  check_pass "Repository root exists: $REPO_ROOT"
else
  check_fail "Repository root missing: $REPO_ROOT"
fi

for dir in config shell apps services lib scripts; do
  if [ -d "${REPO_ROOT}/${dir}" ]; then
    check_pass "Directory exists: ${dir}/"
  else
    check_fail "Directory missing: ${dir}/"
  fi
done

# ============================================================
# Configuration Files
# ============================================================
printf '\n%b--- Configuration ---%b\n' "$CYAN" "$NC"

if [ -f "${REPO_ROOT}/config/rc.conf" ]; then
  check_pass "Global config: config/rc.conf"
else
  check_fail "Missing: config/rc.conf"
fi

HOSTNAME=$(hostname | tr '[:upper:]' '[:lower:]' | cut -d. -f1)
if [ -f "${REPO_ROOT}/config/hosts/${HOSTNAME}.conf" ]; then
  check_pass "Host config: config/hosts/${HOSTNAME}.conf"
else
  check_warn "No host config for: ${HOSTNAME}"
fi

# ============================================================
# Platform Detection
# ============================================================
printf '\n%b--- Platform Detection ---%b\n' "$CYAN" "$NC"

if [ -x "${REPO_ROOT}/scripts/detect-platform.sh" ]; then
  check_pass "detect-platform.sh is executable"

  # Run detection and capture output
  if eval "$("${REPO_ROOT}/scripts/detect-platform.sh" 2>/dev/null)"; then
    check_pass "Platform: ${CONFIG_PLATFORM:-unknown}"
    check_pass "Role: ${CONFIG_ROLE:-unknown}"
    check_pass "Host: ${CONFIG_HOST:-unknown}"

    if [ -n "${CONFIG_LAYERS:-}" ]; then
      printf '  Loaded layers:\n'
      echo "$CONFIG_LAYERS" | tr ':' '\n' | while read -r layer; do
        printf '    - %s\n' "$layer"
      done
    fi
  else
    check_fail "detect-platform.sh failed to run"
  fi
else
  check_fail "detect-platform.sh not executable"
fi

# ============================================================
# Symlinks
# ============================================================
printf '\n%b--- Symlinks ---%b\n' "$CYAN" "$NC"

check_symlink() {
  local link="$1" expected="$2"
  if [ -L "$link" ]; then
    local target
    target=$(readlink "$link")
    if [ "$target" = "$expected" ]; then
      check_pass "Symlink OK: $link"
    else
      check_warn "Symlink mismatch: $link -> $target (expected $expected)"
    fi
  elif [ -e "$link" ]; then
    check_warn "Not a symlink: $link"
  else
    check_warn "Missing: $link"
  fi
}

# Check key symlinks
if [ -f "${REPO_ROOT}/shell/bash/.bashrc" ]; then
  check_symlink "$HOME/.bashrc" "${REPO_ROOT}/shell/bash/.bashrc"
fi

if [ -d "${REPO_ROOT}/apps/ghostty" ]; then
  check_symlink "$HOME/.config/ghostty" "${REPO_ROOT}/apps/ghostty"
fi

# ============================================================
# Summary
# ============================================================
printf '\n%b=== Summary ===%b\n' "$CYAN" "$NC"
printf 'Errors:   %d\n' "$ERRORS"
printf 'Warnings: %d\n' "$WARNINGS"

if [ "$ERRORS" -gt 0 ]; then
  printf '\n%bSome checks failed. Please review the errors above.%b\n' "$RED" "$NC"
  exit 1
elif [ "$WARNINGS" -gt 0 ]; then
  printf '\n%bAll critical checks passed, but there are warnings.%b\n' "$YELLOW" "$NC"
  exit 0
else
  printf '\n%bAll checks passed!%b\n' "$GREEN" "$NC"
  exit 0
fi
