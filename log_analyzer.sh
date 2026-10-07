#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE=""
OUTPUT_FILE="$SCRIPT_DIR/reports/security_report.txt"
TOP_N=10

while getopts "f:o:n:h" opt; do
    case "$opt" in
        f) LOG_FILE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        n) TOP_N="$OPTARG" ;;
        *) echo "Usage: $0 [-f LOG_FILE] [-o OUTPUT_FILE] [-n TOP_N]"; exit 0 ;;
    esac
done

if [[ -z "$LOG_FILE" ]]; then
    if [[ -f /var/log/auth.log ]]; then
        LOG_FILE="/var/log/auth.log"
    elif [[ -f /var/log/secure ]]; then
        LOG_FILE="/var/log/secure"
    else
        echo "Error: no auth log found. Use -f to specify one." >&2
        exit 1
    fi
fi

if [[ ! -r "$LOG_FILE" ]]; then
    echo "Error: cannot read $LOG_FILE (try running with sudo)." >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

section() { printf '\n==== %s ====\n' "$1"; }

{
    echo "=============================================="
    echo "        SECURITY LOG ANALYSIS REPORT"
    echo "=============================================="
    echo "Generated : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Host      : $(hostname)"
    echo "Log file  : $LOG_FILE"
    echo "Lines     : $(wc -l < "$LOG_FILE")"

    section "SUMMARY"
    echo "Failed password attempts : $(grep -c "Failed password" "$LOG_FILE")"
    echo "Invalid user attempts    : $(grep -c "Invalid user" "$LOG_FILE")"
    echo "Successful logins        : $(grep -c "Accepted " "$LOG_FILE")"
    echo "Sudo commands executed   : $(grep -c "sudo:.*COMMAND=" "$LOG_FILE")"

    section "TOP $TOP_N IPs WITH FAILED LOGINS"
    grep "Failed password" "$LOG_FILE" \
        | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        | sort | uniq -c | sort -rn | head -n "$TOP_N" \
        | awk '{printf "%-8s %s\n", $1, $2}'

    section "TOP $TOP_N INVALID USERNAMES TRIED"
    grep "Invalid user" "$LOG_FILE" \
        | sed -E 's/.*Invalid user ([^ ]*) from.*/\1/' \
        | sort | uniq -c | sort -rn | head -n "$TOP_N" \
        | awk '{printf "%-8s %s\n", $1, $2}'

    section "SUCCESSFUL LOGINS (user / IP / count)"
    grep "Accepted " "$LOG_FILE" \
        | sed -E 's/.*Accepted [a-z]+ for ([^ ]+) from ([0-9.]+).*/\1 \2/' \
        | sort | uniq -c | sort -rn | head -n "$TOP_N" \
        | awk '{printf "%-8s user=%-15s ip=%s\n", $1, $2, $3}'

    section "SUDO USAGE (user / count)"
    grep "sudo:.*COMMAND=" "$LOG_FILE" \
        | sed -E 's/.*sudo: +([^ ]+) :.*/\1/' \
        | sort | uniq -c | sort -rn | head -n "$TOP_N" \
        | awk '{printf "%-8s %s\n", $1, $2}'

    section "POSSIBLE BRUTE-FORCE (IPs with 10+ failures)"
    grep "Failed password" "$LOG_FILE" \
        | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
        | sort | uniq -c | awk '$1 >= 10 {printf "%-8s %s\n", $1, $2}' | sort -rn

    echo
    echo "---------------- END OF REPORT ----------------"
} > "$OUTPUT_FILE"

echo "Report saved to: $OUTPUT_FILE"

