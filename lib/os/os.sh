#!/usr/bin/env bash

# shellcheck source=./lib/env/env.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/env/env.sh"
# shellcheck source=./lib/log/log.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/log/log.sh"
# shellcheck source=./lib/io/io.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/io/io.sh"

function os_command_is_installed() {
    local name
    name="$1"
    command -v "$name" >/dev/null
}

function has_apt() {
    [ -n "$(command -v apt)" ]
}
function has_dpkg() {
    [ -n "$(command -v dpkg)" ]
}
function unique_id() {
    local length
    local result
    length="$1"
    result="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c "$length")"
    echo "$result"
}
function add_key() {
    if [[ $# == 0 ]]; then
        log_error "No argument was passed to add_key method"
        exit 1
    fi
    if os_command_is_installed "curl"; then
        log_info "adding key $1"
        curl -fsSL "$1" | sudo apt-key add -
    else
        log_error "Cannot add keys since curl was not found in path"
        exit 1
    fi
}
function add_repo() {
    if [[ $# == 0 ]]; then
        log_error "No argument was passed to add_repo method"
        exit 1
    fi
    uuid=$(unique_id 6)
    target="/etc/apt/sources.list.d/$uuid.list"
    counter=0
    while file_exists "$target"; do
        uuid=$(unique_id 6)
        target="/etc/apt/sources.list.d/$uuid.list"
        counter=$((counter + 1))
        if [[ $counter == 10 ]]; then
            exit 1
        fi
    done
    log_info "adding repo : $1 => $target"
    echo "\"$1\"" | sudo tee "$target"
}
function is_root() {
    [ "$EUID" == 0 ]
}
