#!/bin/bash

# Spider2-Lite Evaluation Runner - Shell Script Version
# Usage: ./run_evaluation.sh

echo "Spider2-Lite Evaluation Runner"
echo "=============================="

# Function to get folder choice
get_folder_choice() {
    echo "" >&2
    echo "Select the predicted results folder:" >&2
    echo "1 - blackbox" >&2
    echo "2 - vanna" >&2
    echo "3 - rlsql" >&2
    echo "4 - databricks" >&2
    
    while true; do
        read -p "Enter your choice (1-4): " choice >&2
        case $choice in
            1|2|3|4) echo $choice; return;;
            *) echo "Please enter a number between 1 and 4." >&2;;
        esac
    done
}

# Function to get mode choice
get_mode_choice() {
    echo "" >&2
    echo "Select evaluation mode:" >&2
    echo "1 - sql" >&2
    echo "2 - exec_result" >&2
    
    while true; do
        read -p "Enter your choice (1-2): " choice >&2
        case $choice in
            1) echo "sql"; return;;
            2) echo "exec_result"; return;;
            *) echo "Please enter 1 for sql or 2 for exec_result." >&2;;
        esac
    done
}

# Get user choices
folder_choice=$(get_folder_choice)

mode=$(get_mode_choice)

# Map folder choice to folder name
case $folder_choice in
    1) folder_name="blackbox";;
    2) folder_name="vanna";;
    3) folder_name="rlsql";;
    4) folder_name="databricks";;
esac

# Build the result directory path
result_dir="evaluation_suite/predicted_results_folder/${folder_name}"

# Build and run the command
echo ""
echo "Running evaluation for ${folder_name} with mode ${mode}..."
echo "Command: python evaluation_suite/evaluate_v2.py --mode ${mode} --result_dir ${result_dir} --gold_dir evaluation_suite/gold"
echo "--------------------------------------------------"

# Check if directory exists
if [ ! -d "$result_dir" ]; then
    echo "Warning: Directory $result_dir does not exist!"
    read -p "Do you want to create it? (y/n): " create_dir
    if [ "$create_dir" = "y" ] || [ "$create_dir" = "Y" ]; then
        mkdir -p "$result_dir"
        echo "Created directory: $result_dir"
    else
        echo "Exiting..."
        exit 1
    fi
fi

# Run the evaluation
python evaluation_suite/evaluate_v2.py --mode "$mode" --result_dir "$result_dir" --gold_dir evaluation_suite/gold

if [ $? -eq 0 ]; then
    echo ""
    echo "Evaluation completed successfully!"
else
    echo ""
    echo "Error running evaluation!"
    exit 1
fi