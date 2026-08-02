#!/bin/sh

# =============================================
# sysinfo.sh – System Information
# =============================================

clear

#Colors
if command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    WHITE=$(tput bold; tput setaf 7)      # яркий белый
    CYAN=$(tput setaf 6)                 # голубой
    PURPLE=$(tput setaf 5)               # фиолетовый
    GREEN=$(tput setaf 2)                # зелёный
    RED=$(tput setaf 1)                  # красный
    YELLOW=$(tput setaf 3)               # жёлтый
    NC=$(tput sgr0)                      # сброс
else
    WHITE=''; CYAN=''; PURPLE=''; GREEN=''; RED=''; YELLOW=''; NC=''
fi

#Section
print_section() {
    echo "${CYAN}┌─────────────────────────────────────────────┐${NC}"
    echo "${CYAN}│ ${WHITE}$1${NC}"
    echo "${CYAN}└─────────────────────────────────────────────┘${NC}"
}

print_info() {
    printf "${PURPLE}│ ${WHITE}%-18s${NC} ${GREEN}%s${NC}\n" "$1:" "$2"
}

#Data collect
hostname=$(hostname 2>/dev/null || echo "unknown")
os=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown OS")
kernel=$(uname -r 2>/dev/null || echo "unknown")
uptime=$(uptime -p 2>/dev/null || echo "unknown")
loadavg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//' 2>/dev/null || echo "unknown")

#CPU
if [ -f /proc/cpuinfo ]; then
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null || echo "unknown")
    cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "0")
else
    cpu_model="unknown"
    cpu_cores="0"
fi

#Memory
mem_total=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "N/A")
mem_used=$(free -h 2>/dev/null | grep Mem | awk '{print $3}' || echo "N/A")
mem_percent=$(free 2>/dev/null | grep Mem | awk '{printf "%.1f%%", ($3/$2)*100}' || echo "N/A")

#Disk
disk_total=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "N/A")
disk_used=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "N/A")
disk_percent=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")

#Network
ip_addr=$(ip -4 addr show 2>/dev/null | grep -v 'lo:' | grep -m1 inet | awk '{print $2}' | cut -d/ -f1)
if [ -z "$ip_addr" ]; then
    ip_addr=$(ifconfig 2>/dev/null | grep -v 'lo:' | grep -m1 'inet ' | awk '{print $2}' | cut -d: -f2)
fi
[ -z "$ip_addr" ] && ip_addr="N/A"

#Users
users=$(who 2>/dev/null | wc -l || echo "0")

#Display
echo "${WHITE}  ═══════════════════════════════════════════════${NC}"
echo "${WHITE}  ❄  SYSTEM INFORMATION  ❄${NC}"
echo "${WHITE}  ═══════════════════════════════════════════════${NC}"
echo ""

print_section " System"
print_info "Hostname" "$hostname"
print_info "Operating System" "$os"
print_info "Kernel" "$kernel"
print_info "Uptime" "$uptime"
print_info "Load Average" "$loadavg"
echo ""

print_section " CPU"
print_info "Model" "$cpu_model"
print_info "Cores" "$cpu_cores"
echo ""

print_section " Memory"
print_info "Total" "$mem_total"
print_info "Used" "$mem_used"
print_info "Usage" "$mem_percent"
echo ""

print_section " Disk (/)"
print_info "Total" "$disk_total"
print_info "Used" "$disk_used"
print_info "Usage" "$disk_percent"
echo ""

print_section " Network"
print_info "IP Address" "$ip_addr"
echo ""

print_section " Users"
print_info "Logged in" "$users"
echo ""

echo "${WHITE}  ──────────────────────────────────────────────${NC}"
echo "${PURPLE}  ✦  Ghost System Info  ✦${NC}"
echo ""
