#!/bin/bash

# Read the JSON input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path
if [ -z "$FILE_PATH" ]; then
	exit 0
fi

# Only lint supported file types
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx|json)$ ]]; then
	# Run Biome on the file
	npx biome check --write "$FILE_PATH" 2>/dev/null
fi

exit 0
