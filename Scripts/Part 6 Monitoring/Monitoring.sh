#!/bin/bash

# Center Text Function (Formats Output Nicely)
center_text() {
    local text="$1"
    local width=80 
    local padding=$(( (width - ${#text}) / 2 ))
    [ $(( (width - ${#text}) % 2 )) -ne 0 ] && padding=$((padding + 1))
    printf "%*s%s%*s\n" "$padding" "" "$text" "$padding"
}

# Load environment variables from .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "❌ .env file not found!"
    exit 1
fi

# Ensure required env var is set
if [ -z "$REPORT_FOLDER" ]; then
    echo "❌ REPORT_FOLDER is not defined in your .env file."
    exit 1
fi

# Create the report directory if it doesn't exist
mkdir -p "$REPORT_FOLDER"  

# Prepare report filename
DAY=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_FOLDER/${DAY}_System_Report.txt"

echo "📄 Report will be saved to: $REPORT_FILE"

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "⚠️  Warning: Some sections may require root privileges. Run with sudo for full results."
fi

# REPORT GENERATION
{
    echo "" 
    center_text "📝 DAILY SYSTEM REPORT"
    echo "Generated on: $(date)"
    echo ""

    echo "============================================"
    center_text "🔹 SYSTEM UPTIME"
    echo "============================================"
    uptime
    echo ""

    echo "============================================"
    center_text "🔹 DISK SPACE USAGE"
    echo "============================================"
    command -v df &> /dev/null && df -h | awk '{print $1, $2, $3, $4, $5, $6}' || echo "❌ 'df' command not found."
    echo ""

    echo "============================================"
    center_text "🔹 MEMORY USAGE"
    echo "============================================"
    command -v free &> /dev/null && free -h || echo "❌ 'free' command not found."
    echo ""

    echo "============================================"
    center_text "🔹 FAILED LOGIN ATTEMPTS (LAST 10)"
    echo "============================================"
    LOG_FILE="/var/log/auth.log"
    [ ! -f "$LOG_FILE" ] && [ -f "/var/log/secure" ] && LOG_FILE="/var/log/secure"

    if [ -f "$LOG_FILE" ]; then
        grep "Failed password" "$LOG_FILE" | tail -n 10
    else
        echo "⚠️  Could not check login attempts (log file not found)."
    fi
    echo ""

    echo "============================================"
    center_text "🔹 AVAILABLE SYSTEM UPDATES"
    echo "============================================"
    if command -v apt-get &> /dev/null; then
        apt list --upgradable 2>/dev/null | grep -v "Listing..." || echo "✅ No updates available"
    elif command -v dnf &> /dev/null; then
        dnf check-update || echo "✅ No updates available"
    elif command -v yum &> /dev/null; then
        yum check-update || echo "✅ No updates available"
    else
        echo "⚠️  Unknown package manager. Cannot check for updates."
    fi
    echo ""
} > "$REPORT_FILE"

# Display result
echo "✅ Report saved to: $REPORT_FILE"
echo "🔍 To view the report, run: cat \"$REPORT_FILE\""
