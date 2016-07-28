#!/bin/sh

#Initial values for a script
i=0
max=$1
server=$(uci get wibed.general.api_url)
experiment="WibedTopology"
iface="scanradio"

#Identify my ID
myid=$(uci get wibed.general.node_id)
echo "My ID is $myid"

#Get list of nodes
rm list
wget -q -O - ${server}api/experimentNodes/${experiment} | grep wibed  |  tr  -d [\",] | sed 's/ //g' > /root/list
#check my position in the list
line=$(grep -n "$myid" /root/list | cut -c1)
#easier if we start from zero for the delay
line=$(expr $line - 1)
echo "My position in the list is $line"

delay=$(($line*2))
echo "Sleep for $delay seconds"
sleep $delay
echo "Starting range test"
rm -f test.txt

#Touch the topology results file. Otherwise, if no nodes are in range, the controller fails to build the topology
touch /save/topo.txt

for i in $(seq 1 $max); do
	iw $iface scan > /save/clean.txt
	iw $iface scan | \
	awk '/BSS/ { printf "\n"} /signal/ {SIG=$2} /SSID/ {if (SIG != 0) printf "%s,%s",$2,SIG}' | \
	grep wibed >> test.txt
done
awk -v x=${max} -F, '{OFS=","}{a[$1]+=$2}END{for(i in a){print i, (a[i]/x)}}' test.txt > /save/topo.txt
rm list
rm test.txt

echo "Ended range test"
