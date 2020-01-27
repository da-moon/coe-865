#!/usr/bin/env bash

# shellcheck source=./lib/env/env.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/env/env.sh"
# shellcheck source=./lib/log/log.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/log/log.sh"

function file_exists() {
    local -r file="$1"
    [[ -f "$file" ]]
}
# "extract <file> [path]" "extract any given archive"
function extract() {
    if ! os_command_is_installed "unzip"; then
        log_error "unzip is not available. existing..."
        exit 1
    fi
    if [[ -f "$1" ]]; then
        if [[ "$2" == "" ]]; then
            case "$1" in
            *.rar)
                rar x "$1" "${1%.rar}"/
                if ! os_command_is_installed "rar"; then
                    log_error "rar is not available. existing..."
                    exit 1
                fi
                ;;
            *.tar.bz2) mkdir -p "${1%.tar.bz2}" && tar xjf "$1" -C "${1%.tar.bz2}"/ ;;
            *.tar.gz) mkdir -p "${1%.tar.gz}" && tar xzf "$1" -C "${1%.tar.gz}"/ ;;
            *.tar.xz) mkdir -p "${1%.tar.xz}" && tar xf "$1" -C "${1%.tar.xz}"/ ;;
            *.tar) mkdir -p "${1%.tar}" && tar xf "$1" -C "${1%.tar}"/ ;;
            *.tbz2) mkdir -p "${1%.tbz2}" && tar xjf "$1" -C "${1%.tbz2}"/ ;;
            *.tgz) mkdir -p "${1%.tgz}" && tar xzf "$1" -C "${1%.tgz}"/ ;;

            *.zip)
                if ! os_command_is_installed "unzip"; then
                    log_error "unzip is not available. existing..."
                    exit 1
                fi
                unzip -oq "$1" -d "${1%.zip}"/
                ;;
            # *.zip) unzip "$1" -d "${1%.zip}"/ ;;
            *.7z) 7za e "$1" -o"${1%.7z}"/ ;;
            *) log_error "$1 cannot be extracted." ;;
            esac
        else
            case "$1" in
            *.rar)
                if ! os_command_is_installed "rar"; then
                    log_error "rar is not available. existing..."
                    exit 1
                fi
                rar x "$1" "$2"
                ;;
            *.tar.bz2) mkdir -p "$2" && tar xjf "$1" -C "$2" ;;
            *.tar.gz) mkdir -p "$2" && tar xzf "$1" -C "$2" ;;
            *.tar.xz) mkdir -p "$2" && tar xf "$1" -C "$2" ;;
            *.tar) mkdir -p "$2" && tar xf "$1" -C "$2" ;;
            *.tbz2) mkdir -p "$2" && tar xjf "$1" -C "$2" ;;
            *.tgz) mkdir -p "$2" && tar xzf "$1" -C "$2" ;;
            *.zip)
                if ! os_command_is_installed "unzip"; then
                    log_error "unzip is not available. existing..."
                    exit 1
                fi
                unzip -oq "$1" -d "$2"
                ;;
            # *.zip) unzip "$1" -d "$2" ;;
            *.7z) 7z e "$1" -o"$2"/ ;;
            *) log_error "$1 cannot be extracted." ;;
            esac
        fi
    else
        log_error "$1 cannot be extracted."
    fi
}
function download() {
    local downloader=""
    if [[ $# -lt 1 ]]; then
        echo
        echo "method usage: download [target url]"
        echo
        echo "Optional:"
        echo
        echo -e "  download [target url] [destination]"
        exit 1
    fi
    if os_command_is_installed "axel"; then
        downloader="axel --num-connections=16"
    elif os_command_is_installed "wget"; then
        downloader="wget -q --show-progress"
    else
        log_error "Cannot download target since wget or axel were not found in path."
        exit 1
    fi
    log_info "downloading $1"
    if [[ $# == 2 ]]; then
        if os_command_is_installed "axel"; then
            downloader+=" -o $2"
        else
            downloader+=" -O $2"
        fi
    fi
    downloader+=" $1"
    $downloader
}
