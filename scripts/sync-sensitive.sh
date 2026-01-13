#!/usr/bin/env bash
# Sync sensitive files to/from encrypted cloud storage
# Usage: sync-sensitive.sh [push|pull|status]

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

REMOTE_DIR="$HOME/mnt/dotconfig-secure"
LOCAL_DIR="$REPO_ROOT/apps"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

# Files to sync (relative to apps/)
SENSITIVE_FILES=(
    "Yubico/u2f_keys"
)

# Files with absolute paths (local:remote pairs, remote relative to REMOTE_DIR)
SENSITIVE_PATHS=(
    "$HOME/.config/rclone/rclone.conf:rclone/rclone.conf"
)

check_mount() {
    if ! mountpoint -q "$REMOTE_DIR" 2>/dev/null; then
        printf '%b[error]%b Encrypted mount not available: %s\n' "$RED" "$NC" "$REMOTE_DIR"
        printf 'Start with: systemctl --user start rclone-dotconfig-crypt\n'
        exit 1
    fi
}

cmd_push() {
    check_mount
    printf '%b=== Pushing sensitive files to encrypted storage ===%b\n' "$GREEN" "$NC"

    for file in "${SENSITIVE_FILES[@]}"; do
        local_file="$LOCAL_DIR/$file"
        remote_file="$REMOTE_DIR/$file"

        if [ -f "$local_file" ]; then
            mkdir -p "$(dirname "$remote_file")"
            cp "$local_file" "$remote_file"
            printf '%b[pushed]%b %s\n' "$GREEN" "$NC" "$file"
        else
            printf '%b[skip]%b %s (not found locally)\n' "$YELLOW" "$NC" "$file"
        fi
    done

    # Handle absolute path files
    for pair in "${SENSITIVE_PATHS[@]}"; do
        local_file="${pair%%:*}"
        remote_rel="${pair##*:}"
        remote_file="$REMOTE_DIR/$remote_rel"

        if [ -f "$local_file" ]; then
            mkdir -p "$(dirname "$remote_file")"
            cp "$local_file" "$remote_file"
            printf '%b[pushed]%b %s\n' "$GREEN" "$NC" "$remote_rel"
        else
            printf '%b[skip]%b %s (not found locally)\n' "$YELLOW" "$NC" "$remote_rel"
        fi
    done

    printf '\n%bDone. Files synced to encrypted cloud storage.%b\n' "$GREEN" "$NC"
}

cmd_pull() {
    check_mount
    printf '%b=== Pulling sensitive files from encrypted storage ===%b\n' "$GREEN" "$NC"

    for file in "${SENSITIVE_FILES[@]}"; do
        local_file="$LOCAL_DIR/$file"
        remote_file="$REMOTE_DIR/$file"

        if [ -f "$remote_file" ]; then
            mkdir -p "$(dirname "$local_file")"
            cp "$remote_file" "$local_file"
            printf '%b[pulled]%b %s\n' "$GREEN" "$NC" "$file"
        else
            printf '%b[skip]%b %s (not found in cloud)\n' "$YELLOW" "$NC" "$file"
        fi
    done

    # Handle absolute path files
    for pair in "${SENSITIVE_PATHS[@]}"; do
        local_file="${pair%%:*}"
        remote_rel="${pair##*:}"
        remote_file="$REMOTE_DIR/$remote_rel"

        if [ -f "$remote_file" ]; then
            mkdir -p "$(dirname "$local_file")"
            cp "$remote_file" "$local_file"
            printf '%b[pulled]%b %s\n' "$GREEN" "$NC" "$remote_rel"
        else
            printf '%b[skip]%b %s (not found in cloud)\n' "$YELLOW" "$NC" "$remote_rel"
        fi
    done

    printf '\n%bDone. Files restored from encrypted cloud storage.%b\n' "$GREEN" "$NC"
}

cmd_status() {
    printf '%b=== Sensitive files sync status ===%b\n' "$GREEN" "$NC"

    if mountpoint -q "$REMOTE_DIR" 2>/dev/null; then
        printf 'Mount: %b[OK]%b %s\n\n' "$GREEN" "$NC" "$REMOTE_DIR"
    else
        printf 'Mount: %b[DOWN]%b %s\n\n' "$RED" "$NC" "$REMOTE_DIR"
    fi

    printf '%-30s %-10s %-10s\n' "FILE" "LOCAL" "REMOTE"
    printf '%-30s %-10s %-10s\n' "----" "-----" "------"

    for file in "${SENSITIVE_FILES[@]}"; do
        local_file="$LOCAL_DIR/$file"
        remote_file="$REMOTE_DIR/$file"

        local_status="missing"
        remote_status="missing"

        [ -f "$local_file" ] && local_status="present"
        [ -f "$remote_file" ] && remote_status="present"

        printf '%-30s %-10s %-10s\n' "$file" "$local_status" "$remote_status"
    done

    # Handle absolute path files
    for pair in "${SENSITIVE_PATHS[@]}"; do
        local_file="${pair%%:*}"
        remote_rel="${pair##*:}"
        remote_file="$REMOTE_DIR/$remote_rel"

        local_status="missing"
        remote_status="missing"

        [ -f "$local_file" ] && local_status="present"
        [ -f "$remote_file" ] && remote_status="present"

        printf '%-30s %-10s %-10s\n' "$remote_rel" "$local_status" "$remote_status"
    done
}

case "${1:-status}" in
    push)  cmd_push ;;
    pull)  cmd_pull ;;
    status) cmd_status ;;
    *)
        printf 'Usage: %s [push|pull|status]\n' "$(basename "$0")"
        printf '  push   - Upload local sensitive files to encrypted cloud\n'
        printf '  pull   - Download sensitive files from encrypted cloud\n'
        printf '  status - Show sync status (default)\n'
        exit 1
        ;;
esac
