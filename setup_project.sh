#!/bin/bash
PROJECT_NAME="attendance_tracker_"
RESOURCES_PATH="deploy_agent_tmp_files"

trap user_interupt SIGINT

user_interupt() {
    echo ""
    echo "User has cancelled the process..."
    echo "Archiving and saving your current progress"

    tar -czvf "${WORKSPACE}.tar.gz" "./$WORKSPACE"

    echo "Archive created successfully"

    rm -rf "$WORKSPACE"

    echo "Removed the incomplete workspace"
    echo ""
    echo "Byiiii"
    
    exit 0
}


start_system() {
    echo "What is the version of your workspace: "
    read VERSION

    WORKSPACE="${PROJECT_NAME}${VERSION}"
    
    if [  -d "$WORKSPACE" ]; then
	echo "WORKSPACE already exists..."
	exit
    fi

    echo ""
    echo "Creating your workspace Directory..."
    
    mkdir "$WORKSPACE"

    echo "cloning the project resources..."

    git clone https://github.com/fiacredev/deploy_agent_tmp_files.git

    echo ""
    if [ -d "$RESOURCES_PATH" ]; then
	echo "Resoueces cloned successfully"
    else
	echo "Error during cloning..."
    fi

    echo ""
    echo "Scaffolding WORKSPACE directory[$WORKSPACE]"
    mkdir "$WORKSPACE/Helpers"
    mkdir "$WORKSPACE/reports"

    echo "Empty directories have been created"

    mv "$RESOURCES_PATH/attendance_checker.py" "$WORKSPACE"
    mv "$RESOURCES_PATH/assets.csv" "$WORKSPACE/Helpers"
    mv "$RESOURCES_PATH/config.json" "$WORKSPACE/Helpers"
    touch "$WORKSPACE/reports/reports.log"
    
    echo "Files added in the WORKSPACE directory..."
    echo ""
    rm -rf "$RESOURCES_PATH"
    echo "Environment cleanup successful..."

    marks_configuration
}

marks_configuration() {
    echo ""
    echo "New Marks Configuration"
    read -p "What is the new marks for warning percent: " WARNING_PERCENT
    read -p "What is the new marks for fail percent: " FAIL_PERCENT

    sed -i "s/\"warning\": [0-9]*/\"warning\": $WARNING_PERCENT/" "$WORKSPACE/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $FAIL_PERCENT/" "$WORKSPACE/Helpers/config.json"

    echo ""
    echo "New attendance marks percentage updated...."
    echo ""

    environment_verifier
}

environment_verifier() {
    echo "Verifying environment integrity...."
    if command -v python3 &> /dev/null; then
	echo "Python 3 is already installed"
    else
	echo "Python is not installed"
    fi

    for file in "$WORKSPACE"; do
	if [ -e "$file" ]; then
	    echo "$file Exists"
	else
	    echo "$file is missing"
	fi
    done

    echo ""
    echo "Environment finished verifying..."
}
		
		

start_system
