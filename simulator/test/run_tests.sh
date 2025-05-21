#!/bin/bash


# Ensure the script exits if any command fails
set -e

echo begin
PYTHON_FILE="test_2_constinuous_data.py"

# Arrays of values to test
#types=("gs" "rdm" "all1" "best")
types=("best")  ## dataset type
task_nums=5     ## sorting task number
sizes=(1 2 4)   ## nodiv/div2/div4


# Loop through each combination of task_num, size, and type
for type in "${types[@]}"
do
  for task_num in "${task_nums[@]}"
  do
    for size in "${sizes[@]}"
      do
      echo "Running test_program with type = $type , task_num = $task_num, size = $size"

      # Run the Python program with the current parameters
      python "$PYTHON_FILE"  "$type" "$task_num" "$size" #"$LOG_FILE"
      
      echo "Completed test_program with type = $type ,task_num = $task_num, size = $size"
      echo ""
    done
  done
done