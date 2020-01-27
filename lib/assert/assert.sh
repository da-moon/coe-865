#!/usr/bin/env bash

# shellcheck source=./lib/env/env.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/env/env.sh"
# shellcheck source=./lib/log/log.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/log/log.sh"
# shellcheck source=./lib/os/os.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/os/os.sh"
function assert_is_installed() {
    local -r name="$1"
    if ! os_command_is_installed "$name"; then
        log_error "'$name' is required but cannot be found in the system's PATH."
        exit 1
    fi
}
function assert_not_empty() {
    local -r arg_name="$1"
    local -r arg_value="$2"
    local -r reason="$3"
    if [[ -z "$arg_value" ]]; then
        log_error "'$arg_name' cannot be empty. $reason"
        exit 1
    fi
}
