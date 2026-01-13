#!/usr/bin/env bash
# Detect platform, load config layers, and export environment variables
# Usage: eval "$(~/.dcfg-tsb/scripts/detect-platform.sh)"

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
CONFIG_DIR="${REPO_ROOT}/config"

CONFIG_EXPORT_KEYS=""
CONFIG_LAYERS_STR=""

trim() {
  local s="$1"
  s="${s#"${s%%[!$' \t']*}"}"
  s="${s%"${s##*[!$' \t']}"}"
  printf '%s' "$s"
}

strip_quotes() {
  local v="$1"
  if [[ ${#v} -ge 2 ]]; then
    local first="${v:0:1}" last="${v: -1}"
    if [[ "$first" == '"' && "$last" == '"' ]]; then
      printf '%s' "${v:1:${#v}-2}"
      return
    fi
    if [[ "$first" == "'" && "$last" == "'" ]]; then
      printf '%s' "${v:1:${#v}-2}"
      return
    fi
  fi
  printf '%s' "$v"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

to_env_name() {
  local key
  key=$(printf '%s' "$1" | tr '.-' '__')
  key=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')
  printf 'CONFIG_%s' "$key"
}

record_key() {
  local env="$1"
  if [[ -z "$CONFIG_EXPORT_KEYS" ]]; then
    CONFIG_EXPORT_KEYS="$env"
  else
    CONFIG_EXPORT_KEYS="${CONFIG_EXPORT_KEYS}"$'\n'"${env}"
  fi
}

set_config() {
  local key="$1" value="$2" env
  env=$(to_env_name "$key")
  printf -v "$env" '%s' "$value"
  record_key "$env"
}

get_config() {
  local key="$1" env value
  env=$(to_env_name "$key")
  eval "value=\${$env:-}"
  printf '%s' "$value"
}

append_layer() {
  local file="$1"
  if [[ -z "$CONFIG_LAYERS_STR" ]]; then
    CONFIG_LAYERS_STR="$file"
  else
    CONFIG_LAYERS_STR="$CONFIG_LAYERS_STR:$file"
  fi
}

load_file() {
  local file="$1"
  [[ -r "$file" ]] || return 0
  append_layer "$file"
  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line=$(trim "$line")
    [[ -z "$line" ]] && continue
    IFS='=' read -r key value <<<"$line"
    key=$(trim "$key")
    value=$(trim "$value")
    [[ -z "$key" ]] && continue
    value=$(strip_quotes "$value")
    set_config "$key" "$value"
  done <"$file"
}

detect_platform() {
  local uname_s uname_m
  uname_s=$(uname -s 2>/dev/null || echo unknown)
  uname_m=$(uname -m 2>/dev/null || echo unknown)
  case "$uname_s" in
    Darwin) DETECTED_PLATFORM="darwin" ;;
    Linux) DETECTED_PLATFORM="linux" ;;
    FreeBSD) DETECTED_PLATFORM="freebsd" ;;
    *) DETECTED_PLATFORM="unknown" ;;
  esac
  DETECTED_ARCH=$(to_lower "$uname_m")
}

detect_host() {
  local host
  host=$(hostname 2>/dev/null || echo unknown)
  DETECTED_FQDN=$(to_lower "$host")
  DETECTED_HOST=$(to_lower "${host%%.*}")
}

infer_role() {
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    DETECTED_ROLE="server"
  else
    DETECTED_ROLE="client"
  fi
}

# Load global defaults
load_file "${CONFIG_DIR}/rc.conf"

# Detect system info
detect_host
detect_platform
infer_role

# Set detected values
set_config "host" "$DETECTED_HOST"
set_config "host.fqdn" "$DETECTED_FQDN"
set_config "detected.role" "$DETECTED_ROLE"
set_config "detected.platform" "$DETECTED_PLATFORM"
set_config "detected.arch" "$DETECTED_ARCH"

# Resolve platform (auto -> detected)
PLATFORM_VALUE=$(get_config platform)
if [[ -z "$PLATFORM_VALUE" || "$PLATFORM_VALUE" == "auto" ]]; then
  PLATFORM_VALUE="$DETECTED_PLATFORM"
  set_config "platform" "$PLATFORM_VALUE"
fi

# Load platform config
PLATFORM_FILE="${CONFIG_DIR}/platforms/${PLATFORM_VALUE}.conf"
if [[ -f "$PLATFORM_FILE" ]]; then
  load_file "$PLATFORM_FILE"
  PLATFORM_VALUE=$(get_config platform)
fi

# Resolve role (auto -> detected)
ROLE_VALUE=$(get_config role)
if [[ -z "$ROLE_VALUE" || "$ROLE_VALUE" == "auto" ]]; then
  ROLE_VALUE="$DETECTED_ROLE"
  set_config "role" "$ROLE_VALUE"
fi

# Load role config
ROLE_FILE="${CONFIG_DIR}/roles/${ROLE_VALUE}.conf"
if [[ -f "$ROLE_FILE" ]]; then
  load_file "$ROLE_FILE"
  ROLE_VALUE=$(get_config role)
fi

# Load host config
HOST_FILE="${CONFIG_DIR}/hosts/${DETECTED_HOST}.conf"
if [[ -f "$HOST_FILE" ]]; then
  load_file "$HOST_FILE"
  ROLE_VALUE=$(get_config role)
  PLATFORM_VALUE=$(get_config platform)
fi

# Load local overrides (gitignored)
LOCAL_FILE="${CONFIG_DIR}/local.conf"
if [[ -f "$LOCAL_FILE" ]]; then
  load_file "$LOCAL_FILE"
  ROLE_VALUE=$(get_config role)
  PLATFORM_VALUE=$(get_config platform)
fi

# Final resolution
if [[ -z "$ROLE_VALUE" || "$ROLE_VALUE" == "auto" ]]; then
  ROLE_VALUE="$DETECTED_ROLE"
  set_config "role" "$ROLE_VALUE"
fi

if [[ -z "$PLATFORM_VALUE" || "$PLATFORM_VALUE" == "auto" ]]; then
  PLATFORM_VALUE="$DETECTED_PLATFORM"
  set_config "platform" "$PLATFORM_VALUE"
fi

# Set convenience flags
if [[ "$ROLE_VALUE" == "client" ]]; then
  set_config "is.client" "1"
  set_config "is.server" "0"
else
  set_config "is.client" "0"
  set_config "is.server" "1"
fi

set_config "is.darwin" $([[ "$PLATFORM_VALUE" == "darwin" ]] && echo 1 || echo 0)
set_config "is.linux" $([[ "$PLATFORM_VALUE" == "linux" ]] && echo 1 || echo 0)
set_config "is.freebsd" $([[ "$PLATFORM_VALUE" == "freebsd" ]] && echo 1 || echo 0)

set_config "arch" "$DETECTED_ARCH"
set_config "repo.root" "$REPO_ROOT"
set_config "config.dir" "$CONFIG_DIR"

if [[ -n "$CONFIG_LAYERS_STR" ]]; then
  set_config "layers" "$CONFIG_LAYERS_STR"
fi

set_config "initialized" "1"

# Export all config variables
EXPORT_LIST=$(printf '%s\n' "$CONFIG_EXPORT_KEYS" | sort -u)
OLD_IFS=$IFS
IFS=$'\n'
for env in $EXPORT_LIST; do
  [[ -z "$env" ]] && continue
  eval "value=\${$env:-}"
  printf 'export %s=%q\n' "$env" "$value"
done
IFS=$OLD_IFS
