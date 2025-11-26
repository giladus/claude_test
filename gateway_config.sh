#!/bin/bash

###############################################################################
# Checkpoint Gateway Configuration File
# Instructions: Edit the values below with your gateway details
###############################################################################

# Gateway SSH Connection Details
export GATEWAY_HOST="your.gateway.hostname.com"  # Replace with your gateway hostname or IP
export GATEWAY_USER="admin"                       # Replace with your SSH username
export GATEWAY_PORT="22"                          # SSH port (usually 22)

# Base path on the Checkpoint gateway
# Common paths:
#   - /opt/CPrt-R81.20
#   - /opt/CPrt-R80.40
#   - /opt/CPsuite-R77
export BASE_PATH="/opt/CPrt-R81.20"

# SSH Key Configuration (optional)
# If using SSH key authentication, specify the path to your private key
# export SSH_KEY_PATH="~/.ssh/id_rsa"

###############################################################################
# Advanced Settings (usually don't need to change these)
###############################################################################

# SSH connection timeout in seconds
export SSH_TIMEOUT="10"

# Enable verbose output (set to 1 for verbose mode)
export VERBOSE="0"
