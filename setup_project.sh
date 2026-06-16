#!/usr/bin/env bash

PROJECT_NAME="attendance_tracker_"

cleanup() {
    echo ""
    echo "User cancelled. Saving progress..."

    if [ -n "$WORKSPACE" ] && [ -d "$WORKSPACE" ]; then
        tar -czf "${WORKSPACE}_archive.tar.gz" "$WORKSPACE"
        rm -rf "$WORKSPACE"
        echo "Archive created: ${WORKSPACE}_archive.tar.gz"
    fi

    echo "Cleanup finished."
    exit 1
}

trap cleanup SIGINT

echo "Enter workspace version/name:"
read VERSION

WORKSPACE="${PROJECT_NAME}${VERSION}"

if [ -d "$WORKSPACE" ]; then
    echo "Error: $WORKSPACE already exists."
    exit 1
fi

echo "Creating workspace..."
mkdir -p "$WORKSPACE/Helpers"
mkdir -p "$WORKSPACE/reports"

echo "Checking Python..."
if command -v python3 >/dev/null 2>&1; then
    echo "Python3 is installed."
else
    echo "Warning: Python3 is missing."
fi

cat > "$WORKSPACE/attendance_checker.py" << 'EOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open("Helpers/config.json", "r") as f:
        config = json.load(f)

    if os.path.exists("reports/reports.log"):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename("reports/reports.log", f"reports/reports_{timestamp}.log.archive")

    with open("Helpers/assets.csv", "r") as f, open("reports/reports.log", "w") as log:
        reader = csv.DictReader(f)
        total_sessions = config["total_sessions"]

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row["Names"]
            email = row["Email"]
            attended = int(row["Attendance Count"])

            percentage = (attended / total_sessions) * 100

            if percentage < config["thresholds"]["failure"]:
                message = f"URGENT: {name}, your attendance is {percentage:.1f}%. You will fail this class."
            elif percentage < config["thresholds"]["warning"]:
                message = f"WARNING: {name}, your attendance is {percentage:.1f}%. Please be careful."
            else:
                message = ""

            if message:
                if config["run_mode"] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
EOF

cat > "$WORKSPACE/Helpers/assets.csv" << 'EOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
EOF

cat > "$WORKSPACE/Helpers/config.json" << 'EOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
EOF

cat > "$WORKSPACE/reports/reports.log" << 'EOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
EOF

valid_number() {
    value="$1"

    if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 100 ]; then
        return 0
    else
        return 1
    fi
}

echo ""
read -p "Do you want to update thresholds? Default warning=75, failure=50 (y/n): " choice

if [ "$choice" = "y" ]; then
    while true; do
        read -p "Enter new warning threshold: " WARNING
        if valid_number "$WARNING"; then
            break
        else
            echo "Enter a number between 1 and 100."
        fi
    done

    while true; do
        read -p "Enter new failure threshold: " FAILURE
        if valid_number "$FAILURE"; then
            break
        else
            echo "Enter a number between 1 and 100."
        fi
    done

    python3 - "$WORKSPACE/Helpers/config.json" "$WARNING" "$FAILURE" << 'EOF'
import json
import sys

config_file = sys.argv[1]
warning = int(sys.argv[2])
failure = int(sys.argv[3])

with open(config_file, "r") as f:
    config = json.load(f)

config["thresholds"]["warning"] = warning
config["thresholds"]["failure"] = failure

with open(config_file, "w") as f:
    json.dump(config, f, indent=4)

print("Thresholds updated successfully.")
EOF
fi

echo ""
echo "Verifying workspace..."

for item in "$WORKSPACE" "$WORKSPACE/Helpers" "$WORKSPACE/reports" \
            "$WORKSPACE/attendance_checker.py" \
            "$WORKSPACE/Helpers/assets.csv" \
            "$WORKSPACE/Helpers/config.json" \
            "$WORKSPACE/reports/reports.log"
do
    if [ -e "$item" ]; then
        echo "[OK] $item exists"
    else
        echo "[MISSING] $item"
    fi
done

echo ""
echo "[DONE] Workspace created successfully."
echo "To run the attendance checker:"
echo "cd $WORKSPACE"
echo "python3 attendance_checker.py"
