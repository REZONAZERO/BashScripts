#!/bin/sh

set -euo pipefail

DEFAULT_LOG="/var/log/auth.log"
FAIL_THRESHOLD=3
TIME_WINDOW=300
IGNORE_IPS=("127.0.0.1" "::1" "192.168.1."

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

function show_help() {
    echo "Usage:"
    echo " $0 [options]"
    echo ""
    echo "Options:"
    echo "-f, --file <log-file>       Path to log file (Default: $DEFAULT_LOG)"
    echo "-t, --time <min>            Analyze the last N mins (Default: 5)"
    echo "-p, --threshold <number>    Threshold of the attempts (Default: 3)"
    echo "--all                       Analyze full log file"
    echo "--help                      Show help"
}

LOG_FILE="$DEFAULT_LOG"
TIME_MINUTES=5
ANALYZE_ALL=false
THRESHOLD=$FAIL_TRASHOLD

while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--file)
            LOG_FILE="$2"
            shift 2
            ;;
        -t|--time)
            TIME_MINUTES="$2"
            shift 2
            ;;
        -p|--treshold)
            THRESHOLD="$2"
            shift 2
            ;;
        --all)
            ANALYZE_ALL=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Wrong args: $1" >&2
            show_help
            exit 1
            ;;
    esac
done


if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Error: log file '$LOG_FILE' not found${NC}" >&2
    exit 1
fi


if $ANALYZE_ALL; then
    SINCE_TIMESTAMP=0
    TIME_DESC="all the time"
else
    SINCE_TIMESTAMP=$(date -d "-$TIME_MINUTES minutes" +%s)
    TIME_DESK="Last $TIME_MINUTES mins"
fi


is_ignored_ip() {
    local ip="$1"
    for ignore in "${IGNORE_IPS[@]}"; do
        if [[ "$ip" == "$ignore"* ]]; then
            return 0
        fi
    done
    return 1
}


echo -e "${CYAN}Analyze log: $LOG_FILE${NC}"
echo -e "${CYAN}Time: $TIME_DESC${NC}"
echo -e "${CYAN}Threshold of suspicious attempts: $TRESHOLD${NC}"
echo ""
echo -e "${YELLOW}Attention: filtering by time doesn't added in this version.${NC}"
echo -e "${YELLOW}Analyzing full log file.${NC}"


declare -A ip_count


while IFS= read -r line; do
    if [[ "$line" =~ ([0-9]{1,3}\.){3}[0-9]{1,3} ]]; then
        ip="${BASH_REMATCH[0]}"
        if ! is_ignored_ip "$ip"; then
            ((ip_count["$ip"]++))
        fi
    fi
done < <(grep -E "Failed password|auth failure|Invalid user|Connection refused" "$LOG_FILE")


if [[ ${#ip_count[@]} -eq 0 ]]; then
    echo -e "${GREEN}Relax. Suspicious activity doesn't detected.${NC}"
    exit 0
fi


echo -e "${CYAN}=== Results ===${NC}"
echo "Total unique IPs: ${#ip_count[@]}"


suspicious=0
for ip in "${!ip_count[@]}"; do
    count=${ip_count[$ip]}
    if (( count >= THRESHOLD )); then
        ((suspicious++))
        echo -e "${RED}!!! $ip : $count attempts${NC}"
    else
        echo -e " $ip : count attempts"
    fi
done


echo ""
if (( suspicious > 0 )); then
    echo -e "${RED}Detected $suspicious suspicious IP-addr (>= $THRESHOLD attempts).${NC}"
    echo -e "${YELLOW}Recomendation: look up and action now!${NC}"
else
    echo -3 "${GREEN}Take a rest. All's correct.${NC}
fi
