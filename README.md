# Attendance Tracker Workspace Script

## Description

This shell script creates a complete attendance tracker workspace automatically.

It creates:

- attendance_checker.py
- Helpers/assets.csv
- Helpers/config.json
- reports/reports.log

It also allows the user to update attendance thresholds and includes an archive feature if the process is interrupted.

## How to Run the Script

-First, give the script permission to run: chmod +x setup_project.sh
-Then run: ./setup_project.sh

-Then the script will ask for a workspace version or name:                                  
{Enter workspace version/name:[Name]}
-This will create: attendance_tracker_[Name]
# How to Run the Attendance Checker
After the workspace is created, enter the folder: cd attendance_tracker_[Name]
Then run the Python file using: python3 attendance_checker.py
To cancel the script while its running should use: Ctrl+c
 
