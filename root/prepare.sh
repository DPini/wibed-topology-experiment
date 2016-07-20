#!/bin/sh
### CONFINE WIBED EXPERIMENTS SCRIPT ###
### Unicast experiments ###

hostname=$(cat /proc/sys/kernel/hostname)

printf "Starting WiBED config for node $hostname\n"


printf "Starting range prepare script\n"
uci set wireless.radio1.disabled=0
uci set wireless.radio1.channel=40
uci set wireless.radio1.hwmode=11na
uci set wireless.radio1.htmode=HT40
uci set wireless.radio1.txpower=21
uci set wireless.radio1.country=UZ
uci set wireless.mgmt1=wifi-iface
uci set wireless.mgmt1.device=radio1
uci set wireless.mgmt1.mode=adhoc
uci set wireless.mgmt1.ssid=$hostname
uci set wireless.mgmt1.bssid=02:C0:FF:EE:C0:DE
uci set wireless.mgmt1.encryption=none
uci set wireless.mgmt1.ifname=mgmt1
uci commit wireless

#(sleep 10 && reboot) &

sleep 2 && wifi

