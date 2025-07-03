#! /bin/bash

echo "Searching for a Zombie's... "

ps aux | awk '$8 == "Z" {print $2}' > Zombie_PID.txt
zombie_count=$(wc -l < Zombie_PID.txt)

if [ "$zombie_count" -gt 0 ]; then
	echo "Found $zombie_count zombies! Preparing to eliminate."

	while read -r pid; do
		echo "Banishing zombies with PID: $pid"
		kill -9 "$pid" 2>/dev/null
	done < Zombie_PID.txt
else
	echo "No zombies found. System is pure. "
fi
