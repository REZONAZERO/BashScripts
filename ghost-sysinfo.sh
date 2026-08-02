#!/bin/sh

# =============================================
# sysinfo.sh – System Information
# Ghost-style elegant display
# =============================================

# Clear screen
clear

# ---------- Colors (Ghost theme) ----------
if [ -t 1 ]; then
    # Main colors: white, cyan, purple, green
    WHITE='\033[1;37m'
    CYAN='\033[0;36m'
    PURPLE='\033[0;35m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    NC='\033[0m'   # No Color
else
    WHITE=''; CYAN=''; PURPLE=''; GREEN=''; RED=''; YELLOW=''; NC=''
fi

# ---------- Helper: print section header ----------
print_section() {
    echo "${CYAN}┌─────────────────────────────────────────────┐${NC}"
    echo "${CYAN}│ ${WHITE}$1${NC}"
    echo "${CYAN}└─────────────────────────────────────────────┘${NC}"
}

# ---------- Helper: print key-value pair ----------
print_info() {
    printf "${PURPLE}│ ${WHITE}%-18s${NC} ${GREEN}%s${NC}\n" "$1:" "$2"
}

# ---------- Collect data ----------
hostname=$(hostname 2>/dev/null || echo "unknown")
os=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown OS")
kernel=$(uname -r 2>/dev/null || echo "unknown")
uptime=$(uptime -p 2>/dev/null || echo "unknown")
loadavg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//' 2>/dev/null || echo "unknown")

# CPU info (model)
if [ -f /proc/cpuinfo ]; then
    cpu_model=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null || echo "unknown")
    cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "0")
else
    cpu_model="unknown"
    cpu_cores="0"
fi

# Memory (total and used)
mem_total=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "N/A")
mem_used=$(free -h 2>/dev/null | grep Mem | awk '{print $3}' || echo "N/A")
mem_percent=$(free 2>/dev/null | grep Mem | awk '{printf "%.1f%%", ($3/$2)*100}' || echo "N/A")

# Disk (root partition)
disk_total=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo "N/A")
disk_used=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}' || echo "N/A")
disk_percent=$(df -h / 2>/dev/null | awk 'NR==2 {print $5}' || echo "N/A")

# Network (primary IP)
# Try ip command, fallback to ifconfig
ip_addr=$(ip -4 addr show 2>/dev/null | grep -v 'lo:' | grep -m1 inet | awk '{print $2}' | cut -d/ -f1)
if [ -z "$ip_addr" ]; then
    ip_addr=$(ifconfig 2>/dev/null | grep -v 'lo:' | grep -m1 'inet ' | awk '{print $2}' | cut -d: -f2)
fi
[ -z "$ip_addr" ] && ip_addr="N/A"

# Users logged in
users=$(who 2>/dev/null | wc -l || echo "0")

# ---------- Display ----------
echo "${WHITE}  ═══════════════════════════════════════════════${NC}"
echo "${WHITE}  ✦            SYSTEM INFORMATION  ✦${NC}"
echo "${WHITE}  ═══════════════════════════════════════════════${NC}"
echo ""

# System
print_section " System"
print_info "Hostname" "$hostname"
print_info "Operating System" "$os"
print_info "Kernel" "$kernel"
print_info "Uptime" "$uptime"
print_info "Load Average" "$loadavg"
echo ""

# CPU
print_section " CPU"
print_info "Model" "$cpu_model"
print_info "Cores" "$cpu_cores"
echo ""

# Memory
print_section " Memory"
print_info "Total" "$mem_total"
print_info "Used" "$mem_used"
print_info "Usage" "$mem_percent"
echo ""

# Disk
print_section " Disk (/)"
print_info "Total" "$disk_total"
print_info "Used" "$disk_used"
print_info "Usage" "$disk_percent"
echo ""

# Network
print_section " Network"
print_info "IP Address" "$ip_addr"
echo ""

# Users
print_section " Users"
print_info "Logged in" "$users"
echo ""

# Footer
echo "${WHITE}  ──────────────────────────────────────────────${NC}"
echo "${PURPLE}  ✦            Ghost System Info            ✦${NC}"
echo ""
