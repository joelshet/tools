#!/bin/bash

# First, try to find a valid virtual environment
if [[ -n "$VIRTUAL_ENV" ]]; then
    python_bin="$VIRTUAL_ENV/bin/python"
elif [[ -f ".venv/bin/python" ]]; then
    python_bin="$(pwd)/.venv/bin/python"
elif [[ -f "../.venv/bin/python" ]]; then
    python_bin="$(pwd)/../.venv/bin/python"
else
    echo "ERROR: No activated virtual environment found."
    echo "Please activate your venv or ensure a venv exists in the current/parent directory."
    exit 1
fi

full_path="$ZED_FILE"
if [[ -z "$full_path" ]]; then
    echo "ERROR: ZED_FILE variable is not set."
    exit 1
fi

filename_ext=$(basename "$full_path")
extension="${filename_ext##*.}"

echo "[Running '$filename_ext'] (using venv at $python_bin)"

if [[ "$extension" == "py" ]]; then
    "$python_bin" "$full_path"
else
    echo "Not running: '$filename_ext' is not a .py file"
fi
