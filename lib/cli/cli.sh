#!/usr/bin/env bash

# shellcheck source=./lib/env/env.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/env/env.sh"
# shellcheck source=./lib/log/log.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/log/log.sh"

command_not_found_handle() {
    log_error "$subcommand is not a known subcommand."
    echo -e "\t\t\t\tRun '$progname --help' for a list of known subcommands." >&2
    exit 1
}
progname=$(basename "$0")
if [[ $# == 0 ]]; then
    help
    exit 1
fi
subcommand=$1
case $subcommand in
"" | "-h" | "--help")
    help
    ;;
*)
    shift
    network_"${subcommand}" "$@"
    unset command_not_found_handle
    ;;
esac
