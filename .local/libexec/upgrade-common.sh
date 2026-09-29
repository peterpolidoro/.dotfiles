# Generated from Systems.org; sourced by the upgrade commands.
# Always resolve sibling commands through the real script, including Stow links.
UPGRADE_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
UPGRADE_DRY_RUN=0
UPGRADE_ROOT_GUIX=0
UPGRADE_NAMES=

upgrade_die() { printf '%s\n' "$*" >&2; exit 1; }

upgrade_parse()
{
    for upgrade_arg do
        case "$upgrade_arg" in
            --dry-run) UPGRADE_DRY_RUN=1 ;;
            --root-guix) UPGRADE_ROOT_GUIX=1 ;;
            -h|--help) upgrade_usage; exit 0 ;;
            ''|[!a-zA-Z0-9]*|*[!a-zA-Z0-9._-]*)
                upgrade_die "Invalid option or profile name: $upgrade_arg" ;;
            *) UPGRADE_NAMES="${UPGRADE_NAMES}${UPGRADE_NAMES:+ }$upgrade_arg" ;;
        esac
    done
}

upgrade_run()
{
    if [ "$UPGRADE_DRY_RUN" -eq 1 ]; then
        printf 'Would run:'
        for upgrade_arg do printf ' <%s>' "$upgrade_arg"; done
        printf '\n'
    else
        "$@"
    fi
}

upgrade_child()
{
    upgrade_command=$1
    shift
    if [ "$UPGRADE_DRY_RUN" -eq 1 ]; then
        "$UPGRADE_SCRIPT_DIR/$upgrade_command" --dry-run "$@"
    else
        "$UPGRADE_SCRIPT_DIR/$upgrade_command" "$@"
    fi
}

upgrade_no_profiles()
{
    [ -z "$UPGRADE_NAMES" ] || upgrade_die 'This command does not accept profile names.'
}

upgrade_no_root_option()
{
    [ "$UPGRADE_ROOT_GUIX" -eq 0 ] || upgrade_die 'Use upgrade-guix-root for root Guix maintenance.'
}

upgrade_select_guix()
{
    # A project shell can put a different, single-channel Guix first on PATH.
    UPGRADE_GUIX=${GUIX_UPDATE_GUIX:-${XDG_CONFIG_HOME:-$HOME/.config}/guix/current/bin/guix}
    if [ ! -x "$UPGRADE_GUIX" ]; then
        [ -z "${GUIX_UPDATE_GUIX:-}" ] || upgrade_die "Guix is not executable: $UPGRADE_GUIX"
        UPGRADE_GUIX=$(command -v guix) || upgrade_die 'No Guix executable found.'
        printf 'Bootstrapping user Guix with %s\n' "$UPGRADE_GUIX" >&2
    fi
}

upgrade_check_channels()
{
    UPGRADE_CHANNELS=${GUIX_UPDATE_CHANNELS:-${XDG_CONFIG_HOME:-$HOME/.config}/guix/channels.scm}
    UPGRADE_CANONICAL_CHANNELS=${GUIX_UPDATE_CANONICAL_CHANNELS:-$HOME/Repositories/codeberg/home-config/files/config/guix/channels.scm}
    [ -r "$UPGRADE_CHANNELS" ] || upgrade_die "Missing channel file: $UPGRADE_CHANNELS"
    if [ -f "$UPGRADE_CANONICAL_CHANNELS" ] &&
       ! cmp -s "$UPGRADE_CANONICAL_CHANNELS" "$UPGRADE_CHANNELS"; then
        upgrade_die "Channel files differ. Reconcile $UPGRADE_CHANNELS with $UPGRADE_CANONICAL_CHANNELS before updating. See Systems.org."
    fi
}

upgrade_prepare_profiles()
{
    UPGRADE_PROFILE_ROOT=${GUIX_UPDATE_PROFILE_ROOT:-$HOME/.guix-extra-profiles}
    UPGRADE_MANIFEST_DIR=${GUIX_UPDATE_MANIFEST_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/guix/manifests}
    # Names are validated by upgrade_parse, so this split cannot expand globs.
    if [ -z "$UPGRADE_NAMES" ]; then
        for upgrade_dir in "$UPGRADE_PROFILE_ROOT"/*; do
            [ -d "$upgrade_dir" ] || continue
            upgrade_name=${upgrade_dir##*/}
            case "$upgrade_name" in
                ''|[!a-zA-Z0-9]*|*[!a-zA-Z0-9._-]*)
                    upgrade_die "Invalid installed profile name: $upgrade_name" ;;
            esac
            UPGRADE_NAMES="${UPGRADE_NAMES}${UPGRADE_NAMES:+ }$upgrade_name"
        done
    fi
    # Validate the entire selection before changing the first profile.
    for upgrade_name in $UPGRADE_NAMES; do
        [ -r "$UPGRADE_MANIFEST_DIR/$upgrade_name.scm" ] ||
            upgrade_die "Missing manifest: $UPGRADE_MANIFEST_DIR/$upgrade_name.scm"
    done
}

upgrade_system_kind()
{
    if [ -n "${GUIX_UPDATE_SYSTEM_KIND:-}" ]; then
        UPGRADE_SYSTEM_KIND=$GUIX_UPDATE_SYSTEM_KIND
    elif [ -e /run/current-system ]; then
        UPGRADE_SYSTEM_KIND=guix
    elif [ -r /etc/debian_version ]; then
        UPGRADE_SYSTEM_KIND=debian
    else
        upgrade_die 'Unsupported host OS; this helper supports Debian and Guix System.'
    fi
    case "$UPGRADE_SYSTEM_KIND" in debian|guix) ;; *) upgrade_die 'Unsupported host OS.' ;; esac
}
