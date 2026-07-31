#!/usr/bin/env bash

set -euo pipefail


DEFAULT_LOG="/var/log/auth.log"
FAIL_THRESHOLD=5
TIME_MINUTES=5
IGNORE_IPS=("127.0.0.1" "::1" "192.168.1.")


RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'


show_help() {
    echo "Использование:"
    echo "  $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -f, --file <лог-файл>   путь к файлу лога (по умолчанию: $DEFAULT_LOG)"
    echo "  -t, --time <минуты>     анализировать за последние N минут (по умолчанию: 5)"
    echo "  -p, --threshold <число> порог неудачных попыток для предупреждения (по умолчанию: 5)"
    echo "  --all                   анализировать весь лог (без временных ограничений)"
    echo "  --help                  показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0                      # анализировать /var/log/auth.log за последние 5 минут"
    echo "  $0 -f /var/log/syslog -t 30   # анализировать syslog за последние 30 минут"
    echo "  $0 --all -p 3           # проанализировать весь лог, предупреждать при 3+ попытках"
}


LOG_FILE="$DEFAULT_LOG"
ANALYZE_ALL=false
THRESHOLD=$FAIL_THRESHOLD

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
        -p|--threshold)
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
            echo -e "${RED}Неизвестный аргумент: $1${NC}" >&2
            show_help
            exit 1
            ;;
    esac
done


if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${RED}Ошибка: файл лога '$LOG_FILE' не найден${NC}" >&2
    exit 1
fi


USE_JOURNALCTL=false
if command -v journalctl &>/dev/null && [[ "$LOG_FILE" == "/var/log/auth.log" ]]; then
    USE_JOURNALCTL=true
fi


get_log_entries() {
    if $ANALYZE_ALL; then
        cat "$LOG_FILE"
    elif $USE_JOURNALCTL; then
        journalctl -u ssh --since "-${TIME_MINUTES} minutes" --no-pager 2>/dev/null || \
        journalctl -f -n 0 --since "-${TIME_MINUTES} minutes" --no-pager 2>/dev/null
    else
        local now=$(date +%s)
        local cutoff=$((now - TIME_MINUTES * 60))

        awk -v cutoff="$cutoff" -v now="$now" '
        {
            if ($1 ~ /^[A-Za-z]{3}$/) {
                # Собираем дату: месяц день время
                month = $1
                day = $2
                time = $3
                # Преобразуем месяц в номер (приближённо, без учёта года)
                m["Jan"]=1; m["Feb"]=2; m["Mar"]=3; m["Apr"]=4; m["May"]=5; m["Jun"]=6;
                m["Jul"]=7; m["Aug"]=8; m["Sep"]=9; m["Oct"]=10; m["Nov"]=11; m["Dec"]=12;
                mon = m[month]
                # Получаем текущий год (предполагаем, что логи за текущий год)
                year = strftime("%Y")
                # Формируем строку для date
                datestr = year " " mon " " day " " time
                # Преобразуем в timestamp (используем system date, если есть)
                cmd = "date -d \"" datestr "\" +%s 2>/dev/null"
                cmd | getline ts
                close(cmd)
                if (ts == "") {
                    # Если преобразование не удалось, пропускаем
                    next
                }
                if (ts >= cutoff) {
                    print $0
                }
            }
        }' "$LOG_FILE"
    fi
}


is_ignored_ip() {
    local ip="$1"
    for ignore in "${IGNORE_IPS[@]}"; do
        if [[ "$ip" == "$ignore"* ]]; then
            return 0
        fi
    done
    return 1
}


echo -e "${CYAN}Анализ лога: $LOG_FILE${NC}"
if $ANALYZE_ALL; then
    echo -e "${CYAN}Период: всё время${NC}"
else
    echo -e "${CYAN}Период: последние $TIME_MINUTES минут${NC}"
fi
echo -e "${CYAN}Порог подозрительных попыток: $THRESHOLD${NC}"
echo ""

declare -A ip_count

while IFS= read -r line; do
    if [[ "$line" =~ ([0-9]{1,3}\.){3}[0-9]{1,3} ]]; then
        ip="${BASH_REMATCH[0]}"
        if [[ "$line" =~ "Failed password" || "$line" =~ "authentication failure" || "$line" =~ "Invalid user" || "$line" =~ "Connection refused" ]]; then
            if ! is_ignored_ip "$ip"; then
                ((ip_count["$ip"]++))
            fi
        fi
    fi
done < <(get_log_entries)


if [[ ${#ip_count[@]} -eq 0 ]]; then
    echo -e "${GREEN}✔ Подозрительных активностей не обнаружено.${NC}"
    exit 0
fi


echo -e "${CYAN}=== Отчёт по неудачным попыткам ===${NC}"
echo "Всего уникальных IP: ${#ip_count[@]}"

suspicious=0
for ip in $(for i in "${!ip_count[@]}"; do echo "${ip_count[$i]} $i"; done | sort -nr | awk '{print $2}'); do
    count="${ip_count[$ip]}"
    if (( count >= THRESHOLD )); then
        ((suspicious++))
        echo -e "${RED}⚠ $ip : $count попыток${NC}"
    else
        echo -e "  $ip : $count попыток"
    fi
done

echo ""
if (( suspicious > 0 )); then
    echo -e "${RED}Обнаружено $suspicious подозрительных IP-адресов (>= $THRESHOLD попыток).${NC}"
    echo -e "${YELLOW}Рекомендуется: проверить и принять меры (например, заблокировать через iptables).${NC}"
else
    echo -e "${GREEN}Нет IP, превышающих порог $THRESHOLD.${NC}"
fi
