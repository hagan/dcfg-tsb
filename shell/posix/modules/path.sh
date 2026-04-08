# ~/.dcfg-tsb/shell/posix/modules/path.sh
# PATH adjustments for administrative users

# Add sbin directories for users in sudo/wheel group
if id -nG 2>/dev/null | grep -qwE '(sudo|wheel)'; then
    case ":$PATH:" in
        *:/usr/sbin:*) ;;
        *) export PATH="$PATH:/usr/sbin:/sbin" ;;
    esac
fi
