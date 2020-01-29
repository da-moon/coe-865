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
    log_info "R1: Guelph $(string_red "ETH0") 192.168.98.10 $(string_yellow "ETH1") 10.1.1.1 $(string_green "ETH2") 10.1.2.2"
    log_info "R2: Finch $(string_red "ETH0") 10.1.6.1 $(string_yellow "ETH1") 10.1.4.1 $(string_green "ETH2") 10.1.1.2"
    log_info "R3: Whitby $(string_red "ETH0") 10.1.2.1 $(string_yellow "ETH1") 10.1.7.1 $(string_green "ETH2") 10.1.3.2"
    log_info "R4: Malton $(string_red "ETH0") 10.1.3.1 $(string_yellow "ETH1") 10.1.5.1 $(string_green "ETH2") 10.1.4.2"
    log_info "R5: Brampton $(string_red "ETH0") 10.2.4.1 $(string_yellow "ETH1") 10.2.1.2"
    log_info "R6: Bloor $(string_red "ETH0") 10.2.3.1 $(string_yellow "ETH1") 10.2.4.2"
    log_info "R7: Kipling $(string_red "ETH0") 10.2.2.1 $(string_yellow "ETH1") 10.2.3.2 $(string_green "ETH2") 10.1.6.2"
    log_info "R8: Dixie $(string_red "ETH0") 10.2.1.1 $(string_yellow "ETH1") 10.2.2.2"
    log_info "R9: Danforth $(string_red "ETH0") 10.3.1.1 $(string_yellow "ETH1") 10.3.2.2"
    log_info "R10: Caledon $(string_red "ETH0") 10.3.4.1 $(string_yellow "ETH1") 10.3.1.2"
    log_info "R11: Acton $(string_red "ETH0") 10.3.3.1 $(string_yellow "ETH1") 10.3.4.2"
    log_info "R12: Keele $(string_red "ETH0") 10.3.2.1 $(string_yellow "ETH1") 10.3.3.2 $(string_green "ETH2") 10.1.4.3"
    log_info "R13: Eglinton $(string_red "ETH0") 10.4.1.1 $(string_yellow "ETH1") 10.4.2.2"
    log_info "R14: Clarkson $(string_red "ETH0") 10.1.5.2 $(string_yellow "ETH1") 10.4.4.1 $(string_green "ETH2") 10.4.1.2"
    log_info "R15: TheEx $(string_red "ETH0") 10.4.3.1 $(string_yellow "ETH1") 10.4.4.2"
    log_info "R16: Appleby $(string_red "ETH0") 10.4.2.1 $(string_yellow "ETH1") 10.4.3.2"
    log_info "R17: Ajax $(string_red "ETH0") 10.5.1.1 $(string_yellow "ETH1") 10.5.2.2"
    log_info "R18: York $(string_red "ETH0") 10.1.7.2 $(string_yellow "ETH1") 10.5.4.2 $(string_green "ETH2") 10.5.1.2"
    log_info "R19 Oshawa $(string_red "ETH0") 10.5.4.1 $(string_yellow "ETH1") 10.5.3.1"
    log_info "R20: Bronte $(string_red "ETH0") 10.5.2.1 $(string_yellow "ETH1") 10.5.3.2"
}

function gen_config_R1() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 192.168.98.10 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.1.1.1 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.2.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}
function gen_config_R2() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.1.6.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.1.4.1 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.1.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}

function gen_config_R3() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.1.2.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.1.7.1 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.3.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}
function gen_config_R4() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.1.3.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.1.5.1 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.4.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}

function gen_config_R5() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.2.4.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.2.1.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}
function gen_config_R6() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.2.3.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.2.4.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}
function gen_config_R7() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.2.2.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.2.3.2 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.1.6.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}

function gen_config_R8() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.2.1.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.2.2.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
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
/sbin/ifconfig eth2 10.1.4.3 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}

function gen_config_R13() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.4.1.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.4.2.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}

function gen_config_R14() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.1.5.2 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.4.4.1 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.4.1.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}

function gen_config_R15() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.4.3.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.4.4.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}

function gen_config_R16() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.4.2.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.4.3.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}
function gen_config_R17() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.5.1.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.5.2.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}

function gen_config_R18() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.1.7.2 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.5.4.2 netmask 255.255.255.0 up
/sbin/ifconfig eth2 10.5.1.2 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"

}
function gen_config_R19() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.5.4.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.5.3.1 netmask 255.255.255.0 up
EOF
    chmod +x "$target_path"
}
function gen_config_R20() {
    local target_path="$1"
    cat >"$target_path" <<EOF
#! /usr/bin/env bash
# Damoon Azarpazhooh 500664523
/sbin/ifconfig eth0 10.5.2.1 netmask 255.255.255.0 up
/sbin/ifconfig eth1 10.5.3.2 netmask 255.255.255.0 up
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
    local zone="$1"
    local client="$2"
    local server_ip="$3"
    local target_path="/var/named/$zone.zone"
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
server IN A $server_ip
EOF
    else
        log_error "Cannot generate $target_path since the script was not invoked with sudo"
        exit 1
    fi

}
###################################
function generate_named_conf() {
    local target_path="/etc/named.conf"
    local zone="$1"
    local server_cidr="$2"
    if is_root; then
        log_info "Backing up $target_path to $target_path.bac"
        cp "$target_path" "$target_path.bac"

        cat >"$target_path" <<EOF
options {
        listen-on port 53 { any; };
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
        file "$zone.zone";
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
