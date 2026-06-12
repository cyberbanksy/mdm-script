#!/bin/bash

# Debug version of MDM bypass script
# Designed for testing and troubleshooting

# Enable debugging
set -x

echo "=== DEBUG MDM Bypass Script ==="
echo "Starting with debugging enabled"
echo "Current time: $(date)"
echo "Running as user: $(whoami)"
echo "Architecture: $(uname -m)"
echo "System: $(uname -s)"

# Check architecture first
if [[ $(uname -m) != "arm64" ]]; then
    echo "ERROR: Not Apple Silicon architecture"
    exit 1
fi

# Global constants (same as main script)
readonly DEFAULT_SYSTEM_VOLUME="Macintosh HD"
readonly DEFAULT_DATA_VOLUME="Macintosh HD - Data"

# Logging function
log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEBUG: $1"
}

# Test mounting volumes before proceeding
log_msg "=== Testing Volume Mounting ==="

# Check if volumes exist
log_msg "Checking for system volume..."
if [ -d "/Volumes/Macintosh HD" ]; then
    log_msg "✓ System volume exists"
    system_volume="/Volumes/Macintosh HD"
else
    log_msg "ℹ System volume not mounted (checking if we can mount)"
    # Try mounting
    diskutil mount "Macintosh HD" 2>/dev/null && log_msg "Mounted system volume" || log_msg "Could not mount system volume"
    system_volume="/Volumes/Macintosh HD"
fi

log_msg "Checking for data volume..."
if [ -d "/Volumes/Macintosh HD - Data" ]; then
    log_msg "✓ Data volume exists"
    data_volume="/Volumes/Macintosh HD - Data"
else
    log_msg "ℹ Data volume not mounted"
    data_volume="/Volumes/Macintosh HD - Data"
fi

# Check if we can access the system volume for writing
log_msg "Testing system volume write access..."
if [ -w "$system_volume/etc/hosts" ]; then
    log_msg "✓ Write access to /etc/hosts confirmed" 
else
    log_msg "⚠ Write access to /etc/hosts restricted"
fi

# Check if we can create files  
log_msg "Testing file creation..."

# Create debug file to confirm we have write access 
touch "$system_volume/debug_test_$(date +%s).tmp" 2>/dev/null && log_msg "✓ Can create files" || log_msg "✗ Cannot create files"

# Show what we've learned so far
log_msg "=== Debug Summary ==="
log_msg "System volume path: $system_volume"
log_msg "Data volume path: $data_volume"
log_msg "Current working directory: $(pwd)"

# List available mounts for verification
log_msg "Available disks and mounts:"
diskutil list | head -20

# If we have access, continue with MDM bypass logic (but in debug mode)
log_msg "Continuing with MDM bypass logic..."

# Test the MDM profile check
if [ -f /usr/bin/profiles ]; then
    log_msg "Testing MDM enrollment check"
    if sudo profiles show -type enrollment >/dev/null 2>&1; then
        log_msg "MDM is currently enrolled"
    else
        log_msg "MDM is not currently enrolled"
    fi
else
    log_msg "Cannot check enrollment (likely not in normal mode)"
fi

log_msg "Debug script completed successfully - no action taken"
