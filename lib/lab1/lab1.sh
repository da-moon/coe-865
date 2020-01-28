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
function generate_config() {
    local target_path="$1"
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
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
EOF
    local INDEX=0
    netmask=$(cidr2netmask "$cidr")

    for value in ${ips}; do
        cat >>"$target_path" <<EOF
/sbin/ifconfig eth${INDEX} $value netmask $netmask up
EOF
        let INDEX=${INDEX}+1
    done
    log_info "Generation of interface setup config file was succesful and it was stored at $target_path"
    chmod +x "$target_path"
    log_info "setting $target_path as executable was successful"
}

function turn_off_ip_forwarding() {
    cat >/proc/sys/net/ipv4/ip_forward <<EOF
    0
EOF
    log_info "IP Forwarding was turned off successfully"
}
function turn_on_ip_forwarding() {
    cat >/proc/sys/net/ipv4/ip_forward <<EOF
    1
EOF
    log_info "IP Forwarding was turned on successfully"
}
function show_interface_status() {
    log_info "Showing interface status with /sbin/ifconfig"
    /sbin/ifconfig -a
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
    if is_root; then
        log_info "removing default route"
        /sbin/route delete default
    else
        log_error "Cannot remove default root since the script was not invoked with sudo"
        exit 1
    fi

}
###################################
# ROUTER Config
# keel
# acton

function list_router_information() {
    # log_info "R1: Guelph $(string_blue)"
    # log_info "R2: Finch $(string_blue)"
    # log_info "R3: Whitby $(string_blue)"
    # log_info "R4: Malton $(string_blue)"
    # log_info "R5: Brampton $(string_blue)"
    # log_info "R6: Bloor $(string_blue)"
    # log_info "R7: Kipling $(string_blue)"
    # log_info "R8: Dixie $(string_blue)"
    log_info "R9: Danforth $(string_red "ETH0") 10.3.1.1 $(string_yellow "ETH1") 10.3.2.2"
    log_info "R10: Caledon $(string_red "ETH0") 10.3.4.1 $(string_yellow "ETH1") 10.3.1.2"
    log_info "R11: Acton $(string_red "ETH0") 10.3.3.1 $(string_yellow "ETH1") 10.3.4.2"
    log_info "R12: Keele $(string_red "ETH0") 10.3.2.1 $(string_yellow "ETH1") 10.3.3.2"
    # log_info "R13: Eglinton $(string_blue)"
    # log_info "R14: Clarkson $(string_blue)"
    # log_info "R15: TheEx $(string_blue)"
    # log_info "R16: Appleby $(string_blue)"
    # log_info "R17: Ajax $(string_blue)"
    # log_info "R18: York $(string_blue)"
    # log_info "R19 Oshawa $(string_blue)"
    # log_info "R20: Bronte $(string_blue)"
}
function gen_config_R9() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.3.1.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.3.2.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}
function gen_config_R10() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.3.4.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.3.1.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}
function gen_config_R11() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.3.3.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.3.4.2 netmask 255.255.255.0 up

EOF
    chmod +x "$target_path"

}
function gen_config_R12() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.3.2.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.3.3.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}
###################################
# R11 Server
# R10 Client
function server_dns_setup() {
    local zone="$1"
    local client="$2"
    local server="$3"
    local server_ip=$(echo $server | cut -d'/' -f1)
    log_info "generating $zone zone file for server $server_ip and client $client"
    generate_dns_zonefile $zone $client $server_ip
    log_info "generating /etc/named.conf file for zone $zone and server $server"
    generate_named_conf "$zone" "$server"
    log_info "generating /etc/resolv.conf file for zone $zone and server $server_ip"
    generate_resolv_conf "$zone" "$server_ip"
}
function client_dns_setup() {
    local zone="$1"
    local server_ip="$2"
    log_info "generating /etc/resolv.conf file for zone $zone and server $server_ip"
    generate_resolv_conf "$zone" "$server_ip"
}
function generate_dns_zonefile() {
    local target_path="/etc/sample.zone"
    local zone="$1"
    local client="$2"
    local server_ip="$3"
    local TTL=86400
    if is_root; then
        cat >"$target_path" <<EOF
\$TTL $TTL
\$ORIGIN $zone.
@ 1D IN SOA dns.$zone. hostmaster.$zone. (
                        1       ; serial
                        3H      ; refresh
                        15M     ; retry
                        1W      ; expiry
                        1D )    ; minimum
;
;
@ 1D IN NS dns.$zone            ; inet address of the name server
1D IN MX 10 mail.$zone          ; mail server
;
; dns and mail server addresses
;
dns IN A $server_ip
mail IN A $server_ip
;
; address
;
client IN A $client
EOF
    else
        log_error "Cannot generate $target_path since the script was not invoked with sudo"
        exit 1
    fi

}
###################################
function generate_named_conf() {
    local target_path="/etc/named.conf"
    local file="/etc/sample.zone"
    local zone="$1"
    local server_cidr="$2"
    if is_root; then
        log_info "Backing up $target_path to $target_path.bac"
        cp "$target_path" "$target_path.bac"

        cat >"$target_path" <<EOF
options {
        listen-on port 53 { 127.0.0.1; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        allow-query     { localhost;$server_cidr; };
        recursion yes;
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};
zone "$zone"  {
        type master;
        notify no;
        allow-query { any; };
        file "$file";
};
include "/etc/named.rfc1912.zones";
EOF
    else
        log_error "Cannot generate $target_path since the script was not invoked with sudo"
        exit 1
    fi
}

###################################
function generate_resolv_conf() {
    local target_path="/etc/resolv.conf"
    local zone="$1"
    local server_ip="$2"
    if is_root; then
        log_info "Backing up $target_path to $target_path.bac"
        cp "$target_path" "$target_path.bac"
        cat >"$target_path" <<EOF
domain $zone
search $zone
nameserver $server_ip
EOF
    else
        log_error "Cannot generate $target_path since the script was not invoked with sudo"
        exit 1
    fi
}

###################################
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
