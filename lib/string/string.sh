#!/usr/bin/env bash

# Return true (0) if the first string contains the second string
function string_contains() {
    local -r haystack="$1"
    local -r needle="$2"

    [[ "$haystack" == *"$needle"* ]]
}

# Returns true (0) if the first string (assumed to contain multiple lines)
# contains the second string (needle).
# The needle can contain regular expressions.
function string_multiline_contains() {
    local -r haystack="$1"
    local -r needle="$2"
    echo "$haystack" | grep -q "$needle"
}

# Convert the given string to uppercase
function string_to_uppercase() {
    local -r str="$1"
    echo "$str" | awk '{print toupper($0)}'
}
# eg .
# string_strip_prefix "foo=bar" "foo="  ===> "bar"
# string_strip_prefix "foo=bar" "*="    ===> "bar"
function string_strip_prefix() {
    local -r str="$1"
    local -r prefix="$2"
    echo "${str#$prefix}"
}

# eg:
# string_strip_suffix "foo=bar" "=bar"  ===> "foo"
# string_strip_suffix "foo=bar" "=*"    ===> "foo"
function string_strip_suffix() {
    local -r str="$1"
    local -r suffix="$2"
    echo "${str%$suffix}"
}

# Return true if the given response is empty or "null"
# "null" is from jq parsing.
function string_is_empty_or_null() {
    local -r response="$1"
    [[ -z "$response" || "$response" == "null" ]]
}
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
function string_colorify() {
    local -r input="$2"
    # checking for colour availablity
    ncolors=$(tput colors)
    if [[ $ncolors -ge 8 ]]; then
        local -r color_code="$1"
        echo -e "\e[1m\e[$color_code"m"$input\e[0m"
    else
        echo -e "$input"
    fi
}

function string_blue() {
    local -r color_code="34"
    local -r input="$1"
    echo -e "$(string_colorify "${color_code}" "${input}")"
}
function string_yellow() {
    local -r color_code="93"
    local -r input="$1"
    echo -e "$(string_colorify "${color_code}" "${input}")"
}

function string_green() {
    local -r color_code="32"
    local -r input="$1"
    echo -e "$(string_colorify "${color_code}" "${input}")"
}

function string_red() {
    local -r color_code="31"
    local -r input="$1"
    echo -e "$(string_colorify "${color_code}" "${input}")"
}
