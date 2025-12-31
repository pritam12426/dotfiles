#!/bin/bash

# Description / summary =======================================================
# This script adds a download task to an aria2c server via JSON-RPC.
# It requires the ARIA2C_SESSION_TOKEN environment variable to be set.
# Make sure the aria2c server is running and accessible at localhost:6800.
# script name: aria2c_add_download.sh
# ===============================================================================


curl -X POST http://localhost:6800/jsonrpc \
	-H "Content-Type: application/json" \
	-d '{
    "jsonrpc": "2.0",
    "id": "'$(date +%s)'",
    "method": "aria2.addUri",
    "params": [
      "token:'${ARIA2C_SESSION_TOKEN}'",
      ["https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"]
    ]
  }'
