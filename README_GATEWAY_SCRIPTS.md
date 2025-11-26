# Checkpoint Gateway File Verification Scripts

## Overview

These scripts connect to a Checkpoint gateway via SSH and **verify** the status of critical CVPN configuration and portal files.

**IMPORTANT: These scripts DO NOT modify any files** - they only check and report on file status.

## Files Included

1. **checkpoint_gateway_verify.sh** - Main verification script
2. **gateway_config.sh** - Configuration file for gateway connection details

## File Categories

The script checks four categories of files:

### 1. Public Config Files (MUST BE PATCHED - NEVER OVERWRITTEN)
- `cvpnd.C`
- These files contain custom configurations that must be preserved
- Action: **PATCH only** (add content, don't replace)

### 2. Internal Config Files (CAN BE OVERWRITTEN)
- `conf/includes/Login.location.conf`
- `conf/includes/Main.virtualhost.conf`
- `conf/includes/Portal.location.conf`
- Action: **OVERWRITE allowed** during updates

### 3. Portal Files (CAN BE OVERWRITTEN)
- Various PHP and JavaScript files in htdocs directories
- Action: **OVERWRITE allowed** during updates

### 4. SNX/C-Shell Files (CAN BE OVERWRITTEN)
- JAR files, CAB files, installation scripts
- Action: **OVERWRITE allowed** during updates

## Setup Instructions

### Step 1: Configure Gateway Connection

Edit `gateway_config.sh` and set your gateway details:

```bash
export GATEWAY_HOST="your.gateway.hostname.com"
export GATEWAY_USER="admin"
export GATEWAY_PORT="22"
export BASE_PATH="/opt/CPrt-R81.20"
```

### Step 2: Set Up SSH Access

Ensure you have SSH access to the gateway:

**Option A: Using SSH Key (Recommended)**
```bash
# Copy your SSH public key to the gateway
ssh-copy-id -p 22 admin@your.gateway.hostname.com
```

**Option B: Using Password**
- You'll be prompted for password when the script runs

### Step 3: Make Scripts Executable

```bash
chmod +x checkpoint_gateway_verify.sh
chmod +x gateway_config.sh
```

## Usage

### Method 1: Using Configuration File

```bash
# Source the configuration file
source gateway_config.sh

# Run the verification script
./checkpoint_gateway_verify.sh
```

### Method 2: Command Line Arguments

```bash
./checkpoint_gateway_verify.sh <gateway_host> <username> [port]
```

Example:
```bash
./checkpoint_gateway_verify.sh gw.company.com admin 22
```

### Method 3: Environment Variables

```bash
GATEWAY_HOST=gw.company.com GATEWAY_USER=admin ./checkpoint_gateway_verify.sh
```

## Output

The script will display:

1. **Connection Test** - Verifies SSH connectivity
2. **Summary Report** - Overview of file categories
3. **File Status** - For each file:
   - ✅ **[EXISTS]** - File found (shows size, date, recommended action)
   - ❌ **[MISSING]** - File not found on gateway
4. **Category Summary** - Count of found/missing files per category

### Example Output

```
========================================
PUBLIC CONFIG FILES (Must be PATCHED only)
========================================

[EXISTS] cvpnd.C
         Action: PATCH - Do NOT overwrite
         Info: 4.5K Jan 15 10:23

Summary: 1 found, 0 missing

========================================
INTERNAL CONFIG FILES (Can be overwritten)
========================================

[EXISTS] conf/includes/Login.location.conf
         Action: OVERWRITE allowed
         Info: 2.1K Feb 10 14:45

[MISSING] conf/includes/Main.virtualhost.conf
          Path: /opt/CPrt-R81.20/conf/includes/Main.virtualhost.conf

Summary: 1 found, 1 missing
```

## Troubleshooting

### SSH Connection Failed

**Problem:** Cannot connect to gateway

**Solutions:**
1. Verify gateway host/IP is correct
2. Check SSH port (usually 22)
3. Ensure SSH service is running on gateway
4. Verify firewall rules allow SSH
5. Test manual connection: `ssh -p 22 admin@gateway.host`

### Permission Denied

**Problem:** SSH authentication fails

**Solutions:**
1. Verify username is correct
2. Check SSH key is properly configured
3. Try password authentication
4. Verify user has necessary permissions on gateway

### Files Not Found

**Problem:** All files show as [MISSING]

**Solutions:**
1. Verify `BASE_PATH` in configuration
2. Check Checkpoint version (path may differ)
3. Ensure user has read permissions
4. Verify Checkpoint installation is complete

### Common Checkpoint Base Paths

- R81.20: `/opt/CPrt-R81.20`
- R81.10: `/opt/CPrt-R81.10`
- R80.40: `/opt/CPrt-R80.40`
- R77.x: `/opt/CPsuite-R77`

## Security Notes

1. **SSH Keys:** Use SSH key authentication instead of passwords
2. **Read-Only:** This script only reads files, never modifies them
3. **Permissions:** Ensure the SSH user has minimal necessary permissions
4. **Audit:** Review script contents before running on production systems

## File Actions Reference

| File Category | Action Type | Description |
|--------------|-------------|-------------|
| Public Config | **PATCH** | Must preserve custom content, only add new content |
| Internal Config | **OVERWRITE** | Can be completely replaced during updates |
| Portal Files | **OVERWRITE** | Can be completely replaced during updates |
| SNX Files | **OVERWRITE** | Can be completely replaced during updates |

## Next Steps

After running verification:

1. Review output to identify missing files
2. For files marked **[EXISTS]**, note the recommended action
3. Use findings to plan Hotfix/update installation strategy
4. For Public Config files, ensure patch process preserves custom content
5. For Internal/Portal/SNX files, direct overwrite is safe

## Support

For issues or questions:
- Review this README
- Check Checkpoint documentation for your gateway version
- Verify SSH connectivity manually before running scripts
