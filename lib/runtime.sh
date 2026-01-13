# shellcheck shell=sh
# Runtime configuration library for dcfg-tsb
# Provides config loading and module toggling functions
# Compatible with bash, zsh, and POSIX sh

# Optimized key-to-env conversion using shell builtins where available
__config_key_to_env() {
  local key="$1"
  # Use zsh/bash builtins if available (much faster than tr)
  if [ -n "$ZSH_VERSION" ]; then
    key="${key//[.-]/_}"
    key="${(U)key}"
  elif [ -n "$BASH_VERSION" ] && [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    key="${key//[.-]/_}"
    key="${key^^}"
  else
    # POSIX fallback: use tr (slower)
    key=$(printf '%s' "$key" | tr '.-' '__' | tr '[:lower:]' '[:upper:]')
  fi
  printf 'CONFIG_%s' "$key"
}

# Get a config value by key
config_get() {
  [ "$#" -ge 1 ] || return 1
  local env value
  env=$(__config_key_to_env "$1")
  eval "value=\${$env:-}"
  printf '%s' "$value"
}

# Check if a config value is truthy
config_is_true() {
  local value
  value=$(config_get "$1")
  case "$value" in
    1|on|true|yes) return 0 ;;
    *) return 1 ;;
  esac
}

# Default module state heuristics (used when module is "auto")
config_default_module_state() {
  local name="$1"
  case "$name" in
    ssh_forward)
      # Enable on servers or when connected via SSH
      if [ "${CONFIG_IS_SERVER:-0}" = "1" ]; then
        return 0
      fi
      if [ -n "${SSH_CONNECTION:-}" ]; then
        return 0
      fi
      return 1
      ;;
    gpg_agent)
      # Enable on clients or macOS
      if [ "${CONFIG_IS_CLIENT:-0}" = "1" ] || [ "${CONFIG_PLATFORM:-}" = "darwin" ]; then
        return 0
      fi
      return 1
      ;;
    version_managers)
      # Disable on FreeBSD servers
      if [ "${CONFIG_PLATFORM:-}" = "freebsd" ] && [ "${CONFIG_IS_SERVER:-0}" = "1" ]; then
        return 1
      fi
      return 0
      ;;
    kubernetes)
      # Enable on servers
      if [ "${CONFIG_IS_SERVER:-0}" = "1" ]; then
        return 0
      fi
      return 1
      ;;
    theming)
      # Enable on clients
      if [ "${CONFIG_IS_CLIENT:-0}" = "1" ]; then
        return 0
      fi
      return 1
      ;;
    history_tools|cargo_tools)
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}

# Check if a module is enabled (handles on/off/auto)
is_module_enabled() {
  [ "$#" -ge 1 ] || return 1
  local name="$1" value
  value=$(config_get "module.$name")
  if [ -z "$value" ]; then
    value="auto"
  fi
  case "$value" in
    1|on|true|yes)
      return 0
      ;;
    0|off|false|no)
      return 1
      ;;
    auto|AUTO|"")
      config_default_module_state "$name"
      return $?
      ;;
    *)
      config_default_module_state "$name"
      return $?
      ;;
  esac
}

# Get loaded config layers
config_layers() {
  config_get layers
}
