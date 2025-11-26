#!/bin/bash

###############################################################################
# Checkpoint Gateway File Verification Script
# Purpose: Connect to Checkpoint gateway via SSH and verify file status
# Action: VERIFICATION ONLY - No files will be modified
#
# USAGE:
#   1. Edit the Configuration section below (lines 39-44) with your gateway details
#   2. Make script executable: chmod +x checkpoint_gateway_verify.sh
#   3. Run: ./checkpoint_gateway_verify.sh
#
#   OR use command line arguments:
#   ./checkpoint_gateway_verify.sh <gateway_host> <username> [port]
#
#   OR use environment variables:
#   GATEWAY_HOST=gateway.host GATEWAY_USER=admin GATEWAY_PASSWORD=pass ./checkpoint_gateway_verify.sh
#
# AUTHENTICATION:
#   - SSH Key (Recommended): Leave GATEWAY_PASSWORD empty
#   - Password: Set GATEWAY_PASSWORD (requires 'sshpass' installed)
#
# FILE CATEGORIES:
#   - Public Config (cvpnd.C): MUST BE PATCHED - Never overwrite!
#   - Internal Config (conf/includes/*.conf): CAN BE OVERWRITTEN
#   - Portal Files (htdocs/HFS, htdocs/SNX): CAN BE OVERWRITTEN
#   - SNX Files (htdocs/SNX/CSHELL): CAN BE OVERWRITTEN
#
# REQUIREMENTS:
#   - SSH access to Checkpoint gateway
#   - For password auth: sshpass package installed
#   - Read permissions on gateway files
#
###############################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GATEWAY_HOST=""
GATEWAY_USER=""
GATEWAY_PASSWORD=""  # Optional: Leave empty to use SSH key authentication
GATEWAY_PORT="22"
BASE_INSTALL_PATH="/opt/CPrt-R81.20"  # Main Checkpoint installation directory

# CVPN public configuration files (must not be overwritten - only patched)
# These are typically in /opt/CPrt-R81.20/conf/
declare -a vsx_template_files_conf_public=(
    "conf/cvpnd.C"
)

# CVPN internal configuration files (can be overwritten)
# These are typically in /opt/CPrt-R81.20/conf/includes/
declare -a vsx_template_files_conf_internal=(
    "conf/includes/Login.location.conf"
    "conf/includes/Main.virtualhost.conf"
    "conf/includes/Portal.location.conf"
)

# CVPN portal files
declare -a vsx_template_files_portal=(
    "htdocs/HFS/js/fileManager.js"
    "htdocs_legacy/HFS/js/fileManager.js"
    "htdocs/SNX/GetSnxBookmarks"
    "htdocs_legacy/SNX/GetSnxBookmarks"
    "htdocs/HFS/.include/controllers/MainController.php"
    "htdocs_legacy/HFS/.include/controllers/MainController.php"
)

# CVPN SNX/C-Shell file links
declare -a vsx_template_files_snx_links=(
    "htdocs/SNX/CSHELL/SNX.jar"
    "htdocs/SNX/CSHELL/SNX.cab"
    "htdocs/SNX/CSHELL/SNX4LINUX.jar"
    "htdocs/SNX/CSHELL/SNX4TIGER.jar"
    "htdocs/SNX/CSHELL/SNX4LINUX30.jar"
    "htdocs/SNX/CSHELL/snx_ver.txt"
    "htdocs/SNX/INSTALL/snx_install_osx.sh"
    "htdocs/SNX/INSTALL/snx_install_linux30.sh"
    "htdocs/SNX/INSTALL/snx_install.sh"
    "htdocs/SNX/CSHELL/SNXAC.jar"
    "htdocs/SNX/CSHELL/SNXAC.cab"
    "htdocs/SNX/CSHELL/SNXAC4x64.jar"
    "htdocs/SNX/CSHELL/SNXAC4x64.cab"
    "htdocs/SNX/CSHELL/SNXAC4LINUX.jar"
    "htdocs/SNX/CSHELL/SNXAC4MAC.jar"
    "htdocs/SNX/CSHELL/SNXAC4LINUX30.jar"
    "htdocs/SNX/CSHELL/snxac_ver.txt"
    "htdocs/SNX/CSHELL/putty.exe"
    "htdocs/SNX/CSHELL/putty.cab"
)

###############################################################################
# Function: ssh_cmd
# Description: Execute SSH command with or without password
# Args: $@ - command to execute
###############################################################################
ssh_cmd() {
    if [ ! -z "$GATEWAY_PASSWORD" ]; then
        # Use sshpass for password authentication
        sshpass -p "$GATEWAY_PASSWORD" ssh -p "${GATEWAY_PORT}" -o StrictHostKeyChecking=no "${GATEWAY_USER}@${GATEWAY_HOST}" "$@"
    else
        # Use SSH key authentication
        ssh -p "${GATEWAY_PORT}" "${GATEWAY_USER}@${GATEWAY_HOST}" "$@"
    fi
}

###############################################################################
# Function: print_header
# Description: Print formatted header
###############################################################################
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

###############################################################################
# Function: check_file_exists
# Description: Check if file exists on remote gateway
# Args: $1 - file path
# Returns: 0 if exists, 1 if not
###############################################################################
check_file_exists() {
    local file_path="$1"
    ssh_cmd "test -f '${file_path}'" 2>/dev/null
    return $?
}

###############################################################################
# Function: get_file_info
# Description: Get file information from remote gateway
# Args: $1 - file path
###############################################################################
get_file_info() {
    local file_path="$1"
    ssh_cmd "ls -lh '${file_path}' 2>/dev/null | awk '{print \$5, \$6, \$7, \$8}'"
}

###############################################################################
# Function: verify_files
# Description: Verify files and report status
# Args: $1 - array name, $2 - file type description, $3 - action type
###############################################################################
verify_files() {
    local -n files_array=$1
    local file_type="$2"
    local action_type="$3"

    print_header "$file_type"

    local found=0
    local missing=0

    for file in "${files_array[@]}"; do
        local full_path="${BASE_INSTALL_PATH}/${file}"

        if check_file_exists "$full_path"; then
            local file_info=$(get_file_info "$full_path")
            echo -e "${GREEN}[EXISTS]${NC} ${file}"
            echo -e "         Action: ${YELLOW}${action_type}${NC}"
            echo -e "         Info: ${file_info}"
            echo ""
            ((found++))
        else
            echo -e "${RED}[MISSING]${NC} ${file}"
            echo -e "          Path: ${full_path}"
            echo ""
            ((missing++))
        fi
    done

    echo -e "Summary: ${GREEN}${found} found${NC}, ${RED}${missing} missing${NC}"
}

###############################################################################
# Function: test_ssh_connection
# Description: Test SSH connection to gateway
###############################################################################
test_ssh_connection() {
    echo -e "${BLUE}Testing SSH connection to ${GATEWAY_HOST}...${NC}"

    # Check if password is set and sshpass is available
    if [ ! -z "$GATEWAY_PASSWORD" ]; then
        if ! command -v sshpass &> /dev/null; then
            echo -e "${RED}Error: sshpass is required for password authentication but not installed${NC}"
            echo -e "${YELLOW}Install sshpass:${NC}"
            echo -e "  - Ubuntu/Debian: sudo apt-get install sshpass"
            echo -e "  - CentOS/RHEL: sudo yum install sshpass"
            echo -e "  - macOS: brew install sshpass"
            echo ""
            echo -e "${YELLOW}Or use SSH key authentication by leaving GATEWAY_PASSWORD empty${NC}\n"
            return 1
        fi
        echo -e "${YELLOW}Using password authentication${NC}"
    else
        echo -e "${YELLOW}Using SSH key authentication${NC}"
    fi

    if ssh_cmd "echo 'Connection successful'" 2>/dev/null; then
        echo -e "${GREEN}SSH connection successful${NC}\n"
        return 0
    else
        echo -e "${RED}SSH connection failed${NC}"
        if [ ! -z "$GATEWAY_PASSWORD" ]; then
            echo -e "${RED}Please check your gateway host, username, and password${NC}\n"
        else
            echo -e "${RED}Please check your gateway host, username, and SSH key configuration${NC}\n"
        fi
        return 1
    fi
}

###############################################################################
# Function: generate_summary_report
# Description: Generate summary report of all files
###############################################################################
generate_summary_report() {
    print_header "VERIFICATION SUMMARY REPORT"

    echo -e "${YELLOW}Gateway:${NC} ${GATEWAY_USER}@${GATEWAY_HOST}:${GATEWAY_PORT}"
    echo -e "${YELLOW}Installation Path:${NC} ${BASE_INSTALL_PATH}"
    echo -e "${YELLOW}Date:${NC} $(date)"
    echo ""

    echo -e "${BLUE}File Categories:${NC}"
    echo -e "  - Public Config Files (PATCH ONLY): ${#vsx_template_files_conf_public[@]} files"
    echo -e "  - Internal Config Files (CAN OVERWRITE): ${#vsx_template_files_conf_internal[@]} files"
    echo -e "  - Portal Files (CAN OVERWRITE): ${#vsx_template_files_portal[@]} files"
    echo -e "  - SNX Links (CAN OVERWRITE): ${#vsx_template_files_snx_links[@]} files"
    echo ""
}

###############################################################################
# Main Script
###############################################################################
main() {
    # Check if required parameters are provided
    if [ -z "$GATEWAY_HOST" ] || [ -z "$GATEWAY_USER" ]; then
        echo -e "${RED}Error: Gateway host and user must be configured${NC}"
        echo ""
        echo "Usage: Edit this script and set:"
        echo "  GATEWAY_HOST=\"your.gateway.host\""
        echo "  GATEWAY_USER=\"your_username\""
        echo "  GATEWAY_PASSWORD=\"your_password\"  # Optional, leave empty for SSH key auth"
        echo "  GATEWAY_PORT=\"22\"  # Optional, default is 22"
        echo "  BASE_INSTALL_PATH=\"/opt/CPrt-R81.20\"  # Adjust as needed"
        echo ""
        echo "Or run with environment variables:"
        echo "  GATEWAY_HOST=your.gateway.host GATEWAY_USER=admin GATEWAY_PASSWORD=yourpass $0"
        echo ""
        echo "Note: Password authentication requires 'sshpass' to be installed"
        exit 1
    fi

    print_header "CHECKPOINT GATEWAY FILE VERIFICATION"
    echo -e "${YELLOW}WARNING: This script will ONLY verify files - NO modifications will be made${NC}\n"

    # Test SSH connection
    if ! test_ssh_connection; then
        exit 1
    fi

    # Generate summary
    generate_summary_report

    # Verify public config files (MUST BE PATCHED - NOT OVERWRITTEN)
    verify_files vsx_template_files_conf_public \
                 "PUBLIC CONFIG FILES (Must be PATCHED only)" \
                 "PATCH - Do NOT overwrite"

    # Verify internal config files (CAN BE OVERWRITTEN)
    verify_files vsx_template_files_conf_internal \
                 "INTERNAL CONFIG FILES (Can be overwritten)" \
                 "OVERWRITE allowed"

    # Verify portal files (CAN BE OVERWRITTEN)
    verify_files vsx_template_files_portal \
                 "PORTAL FILES (Can be overwritten)" \
                 "OVERWRITE allowed"

    # Verify SNX links (CAN BE OVERWRITTEN)
    verify_files vsx_template_files_snx_links \
                 "SNX/C-SHELL FILES (Can be overwritten)" \
                 "OVERWRITE allowed"

    print_header "VERIFICATION COMPLETE"
    echo -e "${GREEN}All file checks completed${NC}"
    echo -e "${YELLOW}Review the output above to see which files exist and their recommended actions${NC}\n"
}

# Allow environment variables to override configuration
if [ ! -z "$1" ]; then
    GATEWAY_HOST="$1"
fi
if [ ! -z "$2" ]; then
    GATEWAY_USER="$2"
fi
if [ ! -z "$3" ]; then
    GATEWAY_PORT="$3"
fi

# Run main function
main
