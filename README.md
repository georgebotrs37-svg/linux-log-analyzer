# Linux Log Analyzer

A lightweight Bash tool that analyzes Linux authentication logs and generates a clear security report: failed logins, attacking IPs, invalid usernames, successful logins, and sudo usage.

أداة Bash خفيفة لتحليل سجلات المصادقة في لينكس وإنتاج تقرير أمني واضح.

## Features

- Counts failed SSH password attempts
- Lists the top attacking IP addresses
- Shows the most frequently tried invalid usernames
- Lists successful logins (user and source IP)
- Summarizes sudo usage per user
- Flags possible brute-force sources (10+ failures from one IP)
- Auto-detects the log file on Debian/Ubuntu and RHEL/CentOS

## Requirements

- Linux with Bash 4+
- Standard tools: `grep`, `sed`, `awk`, `sort`, `uniq`
- Read access to the auth log (usually requires `sudo`)

## Installation

```bash
git clone https://github.com/georgebotrs37-svg/linux-log-analyzer.git
cd linux-log-analyzer
chmod +x log_analyzer.sh
```

## Usage

```bash
sudo ./log_analyzer.sh
cat reports/security_report.txt
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-f FILE` | Log file to analyze | auto-detected |
| `-o FILE` | Output report path | `reports/security_report.txt` |
| `-n NUM`  | Number of top entries to show | `10` |

### Examples

```bash
# Analyze a specific log file
sudo ./log_analyzer.sh -f /var/log/auth.log

# Show only the top 5 entries
sudo ./log_analyzer.sh -n 5

# Save the report somewhere else
sudo ./log_analyzer.sh -o /tmp/report.txt

# Analyze a copied log from another server
./log_analyzer.sh -f ~/server_auth.log
```

## Sample output

```
==============================================
        SECURITY LOG ANALYSIS REPORT
==============================================
Generated : 2026-10-07 18:20:50
Host      : myserver
Log file  : /var/log/auth.log

==== SUMMARY ====
Failed password attempts : 13
Invalid user attempts    : 2
Successful logins        : 1
Sudo commands executed   : 1

==== TOP 10 IPs WITH FAILED LOGINS ====
10       203.0.113.99
2        203.0.113.5
1        198.51.100.7

==== POSSIBLE BRUTE-FORCE (IPs with 10+ failures) ====
10       203.0.113.99
```

## Log locations

| Distribution | Log file |
|--------------|----------|
| Debian / Ubuntu | `/var/log/auth.log` |
| RHEL / CentOS / Fedora | `/var/log/secure` |

## Run it automatically (cron)

Run the analyzer every day at 06:00:

```bash
sudo crontab -e
```

Add this line (adjust the path):

```
0 6 * * * /path/to/linux-log-analyzer/log_analyzer.sh
```

## Project structure

```
linux-log-analyzer/
├── log_analyzer.sh
├── README.md
├── .gitignore
└── reports/
    └── security_report.txt   (generated, git-ignored)
```

## Security note

Generated reports contain IP addresses and usernames, so `reports/*` is git-ignored by default. Do not publish real reports in a public repository.

## Limitations

- Detects patterns from OpenSSH and sudo log messages only
- Does not block attackers; for that, consider `fail2ban`
- Log formats can vary slightly between distributions
