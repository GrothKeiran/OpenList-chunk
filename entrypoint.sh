#!/bin/bash

# Configuration
DATA_DIR="/opt/openlist/data"

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Run migrations or other setup if needed
# ./openlist admin install

# Start the server
exec ./openlist server --data "$DATA_DIR" "$@"
