#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
git clone https://github.com/leninism/UA2F package/UA2F

cat> package/network/config/firewall/files/firewall.user <<EOF
iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 53
iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 53 
iptables -t mangle -N ua2f
iptables -t mangle -A ua2f -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A ua2f -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A ua2f -p tcp --dport 443 -j RETURN 
iptables -t mangle -A ua2f -p tcp --dport 22 -j RETURN
iptables -t mangle -A ua2f -p tcp --dport 80 -j CONNMARK --set-mark 44
iptables -t mangle -A ua2f -m connmark --mark 43 -j RETURN
iptables -t mangle -A ua2f -m set --match-set nohttp dst,dst -j RETURN
iptables -t mangle -A ua2f -j NFQUEUE --queue-num 10010  
iptables -t mangle -A FORWARD -p tcp -m conntrack --ctdir ORIGINAL -j ua2f
iptables -t mangle -A FORWARD -p tcp -m conntrack --ctdir REPLY 
iptables -t nat -N ntp_force_local
iptables -t nat -I PREROUTING -p udp --dport 123 -j ntp_force_local
iptables -t nat -A ntp_force_local -d 0.0.0.0/8 -j RETURN
iptables -t nat -A ntp_force_local -d 127.0.0.0/8 -j RETURN
iptables -t nat -A ntp_force_local -d 192.168.0.0/16 -j RETURN
iptables -t nat -A ntp_force_local -s 192.168.0.0/16 -j DNAT --to-destination 192.168.2.2
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64
EOF
        
cat> package/base-files/files/etc/rc.local <<EOF
# Put your custom commands here that should be executed once
# the system init finished. By default this file does nothing.
ipset create nohttp hash:ip,port hashsize 16384 timeout 300
/usr/dogcom -m dhcp -c /usr/drcom.conf -d -e
exit 0
EOF
