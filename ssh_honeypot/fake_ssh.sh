#! /bin/bash

echo "SSH-2.0-OpenSSH_8.9p1"

#logging
LOG_FILE="var/log/ssh_honeypot.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connection from $SOCAT_PEERADDR" >> $LOG_FILE

while read -r cmd; do
	echo "$cmd" >> $LOG_FILE

	case $cmd in
		*exit*) echo "logout"; break ;;
		*ps*) echo "  PID TTY TIME CMD"; sleep 0.3; echo "	1 ? 00:00:01 init" ;;
		*) echo "bash: $cmd: command not found" ;;
	esac
done
