#!/usr/bin/env bash

# shellcheck source=./lib/env/env.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/env/env.sh"
# shellcheck source=./lib/log/log.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/log/log.sh"
# shellcheck source=./lib/network/network.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/network/network.sh"
# shellcheck source=./lib/array/array.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/array/array.sh"
# shellcheck source=./lib/string/string.sh
source "$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/string/string.sh"

export SUBNET_NR=0
function generate_config_line() {
    interface="$1"
    input="$2"
    local count="$(($3))"
    local netmask
    net_id=$(echo $input | cut -d'/' -f1)
    cidr=$(echo $input | cut -d'/' -f2)
    local ips
    for ((i = 1; i <= $count; i++)); do
        temp=$(get_ip4_random_address "$net_id" "$cidr" "$count")
        if [[ $i == 1 ]]; then
            ips=$(array_join " " "$temp")
        else
            ips=$(array_join " " "$ips" "$temp")
        fi
    done
    netmask=$(cidr2netmask "$cidr")
    declare -a result=()
    for value in ${ips}; do
        if [ ${#result[@]} -eq 0 ]; then
            result=$(array_join "\n" "/sbin/ifconfig $interface $value netmask $netmask")
        else
            result=$(array_join "\n" "$result" "/sbin/ifconfig $interface $value netmask $netmask")
        fi
    done
    echo $result
}
function generate_ipaddr_exec() {
    local target=$HOME/IPaddr.exec
    if [[ $# == 1 ]]; then
        target = "$1"
    fi

    cat >>"$target" <<EOF
    /sbin/ifconfig eth1 10.1.1.20 netmask 255.255.255.0 up
    /sbin/ifconfig eth2 10.1.1.30 netmask 255.255.255.0 up
EOF
    log_info "Generation of interface setup config file was succesful and it was stored at $target"
    chmod +x "$target"
    log_info "setting $target as executable was successful"

}
function turn_off_ip_forwarding() {
    echo 0 >/proc/sys/net/ipv4/ip_forward
    log_info "IP Forwarding was turned off successfully"
}
function turn_on_ip_forwarding() {
    echo 1 >/proc/sys/net/ipv4/ip_forward
    log_info "IP Forwarding was turned on successfully"
}
function show_interface_status() {
    log_info "Showing interface status with /sbin/ifconfig"
    /sbin/ifconfig -a
}
function check_configuration() {
    log_info "Checking configuration"
    /sbin/ifconfig and netstat –i
}
function enable_network_interface() {
    local -r interface="$1"
    assert_not_empty "interface" "$interface" "interface name is needed as an input"
    log_info "enabling interface $interface"
    /sbin/ifconfig "$interface" up
}
function disable_network_interface() {
    local -r interface="$1"
    assert_not_empty "interface" "$interface" "interface name is needed as an input"
    log_info "disabling interface $interface"
    /sbin/ifconfig "$interface" down
}
function show_routing_table() {
    log_info "showing routing table"
    /sbin/route –n
}
function remove_default_route() {
    log_info "removing default route"
    /sbin/route delete default
}

# https://github.com/jeromebarbier/hpe-project/blob/master/vm_tools/generate_heat_template.sh
function generate_subnet() {
    # This function generates a new subnetwork

    CIDR="$1"
    local netmask
    NEXT_SUBNET_ID=$(($SUBNET_NR + 1))
    # Compute new CIDR
    if [ "$SUBNET_NR" != "1" ]; then
        # Compute the first IP address of the next network
        LAST_IP_IN_RANGE=$(ip_int_last_of_range $CIDR)
        NEXT_NETWORK_IP_AS_INT=$(($LAST_IP_IN_RANGE + 1))
        NEXT_NETWORK_IP=$(ip_int2string $NEXT_NETWORK_IP_AS_INT)
        MASK=$(echo $CIDR | cut -d'/' -f2)
        bit_netmask=$(prefix_to_bit_netmask $MASK)
        netmask=$(bit_netmask_to_expanded_netmask "$bit_netmask")

        CIDR="$NEXT_NETWORK_IP/$MASK"
    fi

    GATEWAY=$(ip_int2string $(($(ip_int_last_of_range $CIDR) - 1)))
    netmask=$(echo $netmask | sed "s, ,\\.,g")
    echo "$GATEWAY"
    # eth1 10.1.1.20 netmask 255.255.255.0

    #     echo "  # Private subnetwork #$SUBNET_NR, CIDR=$CIDR, gateway=$GATEWAY
    #   private_subnet$SUBNET_NR:
    #     type: OS::Neutron::Subnet
    #     properties:
    #       network_id: { get_resource: private_net }
    #       cidr: $CIDR
    #       name: $PRIVATE_SUBNET_NAME$SUBNET_NR
    #       dns_nameservers: [ $DNS ]
    #       gateway_ip: $GATEWAY
    #   router_interface$SUBNET_NR:
    #     type: OS::Neutron::RouterInterface
    #     properties:
    #       router_id: { get_resource: router }
    #       subnet_id: { get_resource: private_subnet$SUBNET_NR }
    # "
}

function is_git_available() {
    if ! os_command_is_installed "git"; then
        log_error "git is not available. existing..."
        exit 1
    fi
}
function git_undo_commit() {
    is_git_available
    git reset --soft HEAD~
}
function git_reset_local() {
    is_git_available
    git fetch origin
    git reset --hard origin/master
}
function git_pull_latest() {
    is_git_available
    git pull --rebase origin master

}
function git_list_branches() {
    is_git_available
    git branch -a
}
function git_repo_size() {
    is_git_available

    # do not show output of git bundle create {>/dev/null 2>&1} ...
    git bundle create .tmp-git-bundle --all >/dev/null 2>&1
    # check for existance of du
    if ! os_command_is_installed "du"; then
        log_error "du is not available. existing..."
        exit 1
    fi
    local -r size=$(du -sh .tmp-git-bundle | cut -f1)
    rm .tmp-git-bundle
    echo "$size"
}
function git_user_stats() {
    local -r user_name="$1"
    assert_not_empty "user_name" "$user_name" "git username is needed"
    res=$(git log --author="$user_name" --pretty=tformat: --numstat | gawk -v GREEN='\033[1;32m' -v PLAIN='\033[0m' -v RED='\033[1;31m' 'BEGIN { add = 0; subs = 0 } { add += $1; subs += $2 } END { printf "Total: %s+%s%s / %s-%s%s\n", GREEN, add, PLAIN, RED, subs, PLAIN }')
    echo "$res"
}
