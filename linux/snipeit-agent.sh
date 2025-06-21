#!/bin/bash

# SnipeIT Asset Creation Script
# Script to create assets in SnipeIT with custom fields management
# Compatible with all Linux systems (Debian and CentOS based)

set -e  # Stop script on error

# Default configuration
DEFAULT_STATUS="Pending"
DEFAULT_AUDIT_INTERVAL="1 year"
DEFAULT_EXPECTED_CHECKIN_INTERVAL="2 days"

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for system detection
OS_TYPE=""
PACKAGE_MANAGER=""
INSTALL_CMD=""

# Function to detect operating system
detect_os() {
    log_message "INFO" "Detecting operating system..."
    
    # Detection based on system files
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS_TYPE="$ID"
        log_message "INFO" "System detected: $NAME ($VERSION)"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="rhel"
        log_message "INFO" "System detected: Red Hat Enterprise Linux"
    elif [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
        log_message "INFO" "System detected: Debian"
    else
        log_message "WARNING" "Unable to detect system, using default values"
        OS_TYPE="unknown"
    fi
    
    # Determine package manager
    case $OS_TYPE in
        "ubuntu"|"debian"|"linuxmint"|"pop")
            PACKAGE_MANAGER="apt"
            INSTALL_CMD="apt-get install -y"
            log_message "INFO" "Package manager: APT"
            ;;
        "centos"|"rhel"|"fedora"|"rocky"|"alma"|"amzn")
            PACKAGE_MANAGER="yum"
            # Check if dnf is available (newer)
            if command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
                INSTALL_CMD="dnf install -y"
            else
                INSTALL_CMD="yum install -y"
            fi
            log_message "INFO" "Package manager: $PACKAGE_MANAGER"
            ;;
        "opensuse"|"sles")
            PACKAGE_MANAGER="zypper"
            INSTALL_CMD="zypper install -y"
            log_message "INFO" "Package manager: Zypper"
            ;;
        "arch"|"manjaro")
            PACKAGE_MANAGER="pacman"
            INSTALL_CMD="pacman -S --noconfirm"
            log_message "INFO" "Package manager: Pacman"
            ;;
        *)
            log_message "WARNING" "Unrecognized system, trying APT then YUM"
            PACKAGE_MANAGER="auto"
            ;;
    esac
}

# Function to install dependencies
install_dependencies() {
    log_message "INFO" "Checking and installing dependencies..."
    
    local missing_deps=()
    
    # Check curl
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    # Check jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    # If dependencies are missing, install them
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "INFO" "Missing dependencies: ${missing_deps[*]}"
        log_message "INFO" "Automatic installation..."
        
        case $PACKAGE_MANAGER in
            "apt")
                sudo apt-get update
                sudo $INSTALL_CMD "${missing_deps[@]}"
                ;;
            "yum"|"dnf")
                sudo $INSTALL_CMD "${missing_deps[@]}"
                ;;
            "zypper")
                sudo $INSTALL_CMD "${missing_deps[@]}"
                ;;
            "pacman")
                sudo $INSTALL_CMD "${missing_deps[@]}"
                ;;
            "auto")
                # Try APT first, then YUM
                if command -v apt-get >/dev/null 2>&1; then
                    sudo apt-get update
                    sudo apt-get install -y "${missing_deps[@]}" 2>/dev/null || {
                        log_message "WARNING" "APT failed, trying YUM..."
                        sudo yum install -y "${missing_deps[@]}" 2>/dev/null || {
                            log_message "ERROR" "Unable to install dependencies automatically"
                            log_message "INFO" "Please install manually: ${missing_deps[*]}"
                            return 1
                        }
                    }
                elif command -v yum >/dev/null 2>&1; then
                    sudo yum install -y "${missing_deps[@]}" 2>/dev/null || {
                        log_message "ERROR" "Unable to install dependencies automatically"
                        log_message "INFO" "Please install manually: ${missing_deps[*]}"
                        return 1
                    }
                else
                    log_message "ERROR" "No recognized package manager"
                    log_message "INFO" "Please install manually: ${missing_deps[*]}"
                    return 1
                fi
                ;;
        esac
        
        log_message "SUCCESS" "Dependencies installed successfully"
    else
        log_message "SUCCESS" "All dependencies are already installed"
    fi
}

# Function to calculate dates (multi-OS compatible)
calculate_dates() {
    log_message "INFO" "Calculating dates..."
    
    # Try different methods depending on the system
    if command -v date >/dev/null 2>&1; then
        # Try GNU date (Linux standard)
        AUDIT_DATE=$(date -d "+1 year" +%Y-%m-%d 2>/dev/null || echo "")
        EXPECTED_CHECKIN_DATE=$(date -d "+2 days" +%Y-%m-%d 2>/dev/null || echo "")
        
        # If GNU date failed, try BSD date (macOS)
        if [[ -z "$AUDIT_DATE" ]]; then
            AUDIT_DATE=$(date -v+1y +%Y-%m-%d 2>/dev/null || echo "")
            EXPECTED_CHECKIN_DATE=$(date -v+2d +%Y-%m-%d 2>/dev/null || echo "")
        fi
        
        # If everything failed, use current date
        if [[ -z "$AUDIT_DATE" ]]; then
            AUDIT_DATE=$(date +%Y-%m-%d)
            EXPECTED_CHECKIN_DATE=$(date +%Y-%m-%d)
            log_message "WARNING" "Unable to calculate future dates, using current date"
        fi
    else
        log_message "WARNING" "Command 'date' not found"
        AUDIT_DATE=$(date +%Y-%m-%d)
        EXPECTED_CHECKIN_DATE=$(date +%Y-%m-%d)
    fi
    
    log_message "INFO" "Audit date: $AUDIT_DATE"
    log_message "INFO" "Expected check-in date: $EXPECTED_CHECKIN_DATE"
}

# Function to display help messages
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Script to create assets in SnipeIT
Compatible with all Linux systems (Debian, CentOS, Ubuntu, RHEL, etc.)

OPTIONS:
    -s, --server URL        SnipeIT server URL (required)
    -t, --token TOKEN       SnipeIT API token (required)
    -m, --model MODEL       Asset model name (required)
    -n, --name NAME         Asset name (optional, defaults to hostname)
    -a, --asset-tag TAG     Asset tag (optional)
    -c, --company COMPANY   Company name (optional)
    -l, --location LOCATION Location name (optional)
    -d, --department DEPT   Department name (optional)
    -u, --supplier SUPPLIER Supplier name (optional)
    -p, --purchase-date DATE Purchase date (YYYY-MM-DD, optional)
    -w, --warranty-months MONTHS Warranty months (optional)
    -o, --order-number ORDER Order number (optional)
    -i, --invoice-number INVOICE Invoice number (optional)
    --auto-install          Automatic dependency installation (curl, jq)
    --no-auto-detect        Disable automatic system information detection
    --force-update          Force update of existing assets (update custom fields)
    -v, --verbose           Verbose mode
    -h, --help             Show this help

CUSTOM FIELDS:
    --disks DISKS           Disk(s) (textarea)
    --memory MEMORY         Memory in GB (numeric)
    --vcpu VCPU             vCPU (numeric)
    --hostname HOSTNAME     Hostname (text)
    --ip-address IP         IP address (text)
    --os OS                 Operating system (text)
    --software SOFTWARE     Software (textarea)

AUTO-DETECTION:
    The script automatically detects system information if not provided:
    - CPU cores (vCPU)
    - Memory (RAM) in GB
    - Disk information
    - Operating system
    - IP address
    - Hostname

SUPPORTED SYSTEMS:
    - Ubuntu, Debian, Linux Mint, Pop!_OS (APT)
    - CentOS, RHEL, Fedora, Rocky Linux, AlmaLinux (YUM/DNF)
    - openSUSE, SLES (Zypper)
    - Arch Linux, Manjaro (Pacman)
    - Other Linux distributions

EXAMPLES:
    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "Dell OptiPlex 7090" -n "PC-001" --hostname "pc001.company.com" --ip-address "192.168.1.100" --memory 16 --vcpu 8 --os "Ubuntu 22.04"

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "HP ProBook 450" -n "LAPTOP-001" --hostname "laptop001.company.com" --ip-address "192.168.1.101" --memory 32 --vcpu 16 --os "Windows 11" --disks "SSD 512GB" --software "Office 365, Chrome, Firefox"

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "Dell PowerEdge R740" --hostname "srv-prod-01.company.com" --auto-install

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "Dell PowerEdge R740" --auto-install

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "VM Linux" --no-auto-detect

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "Dell OptiPlex 7090" --force-update --hostname "pc001.company.com" --ip-address "192.168.1.100"

EOF
}

# Function to log messages
log_message() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")
            echo -e "${BLUE}[$timestamp] INFO:${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$timestamp] SUCCESS:${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[$timestamp] WARNING:${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[$timestamp] ERROR:${NC} $message" >&2
            ;;
        "DEBUG")
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${YELLOW}[$timestamp] DEBUG:${NC} $message" >&2
            fi
            ;;
    esac
}

# Function to validate required parameters
validate_required_params() {
    local missing_params=()
    
    [[ -z "$SNIPEIT_SERVER" ]] && missing_params+=("SnipeIT server")
    [[ -z "$API_TOKEN" ]] && missing_params+=("API token")
    [[ -z "$MODEL_NAME" ]] && missing_params+=("model name")
    
    if [[ ${#missing_params[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing parameters: ${missing_params[*]}"
        echo
        show_help
        exit 1
    fi
}

# Function to set default asset name based on hostname
set_default_asset_name() {
    if [[ -z "$ASSET_NAME" ]]; then
        if [[ -n "$HOSTNAME" ]]; then
            ASSET_NAME="$HOSTNAME"
            log_message "INFO" "Using hostname as asset name: $ASSET_NAME"
        else
            # Try to get hostname from system
            local system_hostname=$(hostname 2>/dev/null || echo "")
            if [[ -n "$system_hostname" ]]; then
                ASSET_NAME="$system_hostname"
                log_message "INFO" "Using system hostname as asset name: $ASSET_NAME"
            else
                log_message "ERROR" "No asset name provided and unable to determine hostname"
                log_message "INFO" "Please provide an asset name with --name option or hostname with --hostname option"
                exit 1
            fi
        fi
    fi
}

# Function to validate server URL
validate_server_url() {
    if [[ ! "$SNIPEIT_SERVER" =~ ^https?:// ]]; then
        log_message "ERROR" "Server URL must start with http:// or https://"
        exit 1
    fi
    
    # Remove trailing slash if exists
    SNIPEIT_SERVER=${SNIPEIT_SERVER%/}
}

# Function to get model ID
get_model_id() {
    local model_name="$1"
    
    # Try exact search first
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/models?search=$model_name&limit=10")
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    local model_id=$(echo "$response" | jq -r '.rows[0].id // empty')
    local model_name_found=$(echo "$response" | jq -r '.rows[0].name // empty')
    
    if [[ -z "$model_id" || "$model_id" == "null" ]]; then
        # Try without search parameter to get all models
        response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            "$SNIPEIT_SERVER/api/v1/models?limit=50")
        
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        
        # Use jq to find exact match
        model_id=$(echo "$response" | jq -r --arg name "$model_name" '.rows[] | select(.name == $name) | .id' 2>/dev/null | head -1)
        model_name_found="$model_name"
    fi
    
    if [[ -z "$model_id" || "$model_id" == "null" ]]; then
        return 1
    fi
    
    # Return only the clean model ID
    printf "%s" "$model_id"
}

# Function to get model ID with logging (wrapper)
get_model_id_with_logging() {
    local model_name="$1"
    
    log_message "INFO" "Getting model ID: $model_name"
    
    # Get the model ID without any logging
    local model_id=$(get_model_id "$model_name")
    if [[ $? -ne 0 || -z "$model_id" ]]; then
        log_message "ERROR" "Model '$model_name' not found"
        return 1
    fi
    
    log_message "SUCCESS" "Model found: $model_name (ID: $model_id)"
    printf "%s" "$model_id"
}

# Function to get company ID
get_company_id() {
    if [[ -z "$COMPANY_NAME" ]]; then
        return 0
    fi
    
    log_message "INFO" "Getting company ID: $COMPANY_NAME"
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/companies?search=$COMPANY_NAME&limit=1")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting company"
        return 0
    fi
    
    local company_id=$(echo "$response" | jq -r '.rows[0].id // empty')
    
    if [[ -z "$company_id" || "$company_id" == "null" ]]; then
        log_message "WARNING" "Company '$COMPANY_NAME' not found"
        return 0
    fi
    
    log_message "SUCCESS" "Company found with ID: $company_id"
    echo "$company_id"
}

# Function to get location ID
get_location_id() {
    if [[ -z "$LOCATION_NAME" ]]; then
        return 0
    fi
    
    log_message "INFO" "Getting location ID: $LOCATION_NAME"
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/locations?search=$LOCATION_NAME&limit=1")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting location"
        return 0
    fi
    
    local location_id=$(echo "$response" | jq -r '.rows[0].id // empty')
    
    if [[ -z "$location_id" || "$location_id" == "null" ]]; then
        log_message "WARNING" "Location '$LOCATION_NAME' not found"
        return 0
    fi
    
    log_message "SUCCESS" "Location found with ID: $location_id"
    echo "$location_id"
}

# Function to get department ID
get_department_id() {
    if [[ -z "$DEPARTMENT_NAME" ]]; then
        return 0
    fi
    
    log_message "INFO" "Getting department ID: $DEPARTMENT_NAME"
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/departments?search=$DEPARTMENT_NAME&limit=1")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting department"
        return 0
    fi
    
    local department_id=$(echo "$response" | jq -r '.rows[0].id // empty')
    
    if [[ -z "$department_id" || "$department_id" == "null" ]]; then
        log_message "WARNING" "Department '$DEPARTMENT_NAME' not found"
        return 0
    fi
    
    log_message "SUCCESS" "Department found with ID: $department_id"
    echo "$department_id"
}

# Function to get supplier ID
get_supplier_id() {
    if [[ -z "$SUPPLIER_NAME" ]]; then
        return 0
    fi
    
    log_message "INFO" "Getting supplier ID: $SUPPLIER_NAME"
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/suppliers?search=$SUPPLIER_NAME&limit=1")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting supplier"
        return 0
    fi
    
    local supplier_id=$(echo "$response" | jq -r '.rows[0].id // empty')
    
    if [[ -z "$supplier_id" || "$supplier_id" == "null" ]]; then
        log_message "WARNING" "Supplier '$SUPPLIER_NAME' not found"
        return 0
    fi
    
    log_message "SUCCESS" "Supplier found with ID: $supplier_id"
    echo "$supplier_id"
}

# Function to check if asset already exists
check_asset_exists() {
    local asset_tag="$1"
    local asset_name="$2"
    
    log_message "INFO" "Checking if asset exists"
    
    local search_term=""
    if [[ -n "$asset_tag" ]]; then
        search_term="$asset_tag"
    else
        search_term="$asset_name"
    fi
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/hardware?search=$search_term&limit=1")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error checking if asset exists"
        return 1
    fi
    
    local existing_asset=$(echo "$response" | jq -r '.rows[0] // empty')
    
    if [[ -n "$existing_asset" && "$existing_asset" != "null" ]]; then
        local existing_id=$(echo "$existing_asset" | jq -r '.id')
        local existing_name=$(echo "$existing_asset" | jq -r '.name')
        log_message "INFO" "Existing asset found - ID: $existing_id, Name: $existing_name"
        echo "$existing_id"
        return 0
    fi
    
    log_message "INFO" "No existing asset found"
    return 1
}

# Function to get custom field column names
get_custom_field_columns() {
    log_message "INFO" "Getting custom field column names..."
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/customfields")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting custom fields, using default column names"
        return 1
    fi
    
    # Parse custom fields and find the ones we need
    local fields_json=$(echo "$response" | jq -r '.rows // empty')
    if [[ -z "$fields_json" || "$fields_json" == "null" ]]; then
        log_message "WARNING" "No custom fields found, using default column names"
        return 1
    fi
    
    # Extract column names for our fields
    DISKS_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "Disque(s)") | .db_column_name // empty')
    MEMORY_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "Mémoire") | .db_column_name // empty')
    VCPU_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "vCPU") | .db_column_name // empty')
    HOSTNAME_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "Hostname") | .db_column_name // empty')
    IP_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "Adresse IP") | .db_column_name // empty')
    OS_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "OS") | .db_column_name // empty')
    SOFTWARE_COLUMN=$(echo "$fields_json" | jq -r '.[] | select(.name == "Logiciels") | .db_column_name // empty')
    
    # Set defaults if not found
    [[ -z "$DISKS_COLUMN" ]] && DISKS_COLUMN="_snipeit_disques_10"
    [[ -z "$MEMORY_COLUMN" ]] && MEMORY_COLUMN="_snipeit_memoire_9"
    [[ -z "$VCPU_COLUMN" ]] && VCPU_COLUMN="_snipeit_vcpu_8"
    [[ -z "$HOSTNAME_COLUMN" ]] && HOSTNAME_COLUMN="_snipeit_hostname_7"
    [[ -z "$IP_COLUMN" ]] && IP_COLUMN="_snipeit_adresse_ip_6"
    [[ -z "$OS_COLUMN" ]] && OS_COLUMN="_snipeit_os_4"
    [[ -z "$SOFTWARE_COLUMN" ]] && SOFTWARE_COLUMN="_snipeit_logiciels_5"
    
    log_message "DEBUG" "Custom field columns:"
    log_message "DEBUG" "  Disks: $DISKS_COLUMN"
    log_message "DEBUG" "  Memory: $MEMORY_COLUMN"
    log_message "DEBUG" "  vCPU: $VCPU_COLUMN"
    log_message "DEBUG" "  Hostname: $HOSTNAME_COLUMN"
    log_message "DEBUG" "  IP: $IP_COLUMN"
    log_message "DEBUG" "  OS: $OS_COLUMN"
    log_message "DEBUG" "  Software: $SOFTWARE_COLUMN"
}

# Function to update asset custom fields
update_asset_custom_fields() {
    local asset_id="$1"
    
    log_message "INFO" "Updating custom fields for asset ID: $asset_id"
    
    # Build JSON for custom fields update
    local custom_fields_data=$(cat << EOF
{
    "custom_fields": {
        "$DISKS_COLUMN": "$DISKS",
        "$MEMORY_COLUMN": $MEMORY,
        "$VCPU_COLUMN": $VCPU,
        "$HOSTNAME_COLUMN": "$HOSTNAME",
        "$IP_COLUMN": "$IP_ADDRESS",
        "$OS_COLUMN": "$OS",
        "$SOFTWARE_COLUMN": "$SOFTWARE"
    }
}
EOF
)
    
    # Validate JSON before sending
    if ! echo "$custom_fields_data" | jq . >/dev/null 2>&1; then
        log_message "ERROR" "Invalid JSON generated for custom fields update:"
        log_message "ERROR" "$custom_fields_data"
        return 1
    fi
    
    log_message "DEBUG" "Custom fields data to update: $custom_fields_data"
    
    local response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -X PUT \
        -d "$custom_fields_data" \
        "$SNIPEIT_SERVER/api/v1/hardware/$asset_id")
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n -1)
    
    # According to Snipe-IT API docs, they return 200 even on errors
    if [[ $http_code -eq 200 ]]; then
        # Check if the response indicates success or error
        local status=$(echo "$response_body" | jq -r '.status // empty')
        if [[ "$status" == "success" ]]; then
            log_message "SUCCESS" "Asset custom fields updated successfully"
            return 0
        else
            log_message "ERROR" "API returned error status: $status"
            log_message "ERROR" "Response: $response_body"
            return 1
        fi
    else
        log_message "ERROR" "Error updating asset custom fields - HTTP Code: $http_code"
        log_message "ERROR" "Response: $response_body"
        return 1
    fi
}

# Function to create asset
create_asset() {
    local model_id="$1"
    local company_id="$2"
    local location_id="$3"
    local department_id="$4"
    local supplier_id="$5"
    
    log_message "INFO" "Creating asset: $ASSET_NAME"
    log_message "DEBUG" "Model ID: $model_id"
    log_message "DEBUG" "Company ID: $company_id"
    log_message "DEBUG" "Location ID: $location_id"
    log_message "DEBUG" "Department ID: $department_id"
    log_message "DEBUG" "Supplier ID: $supplier_id"
    
    # Validate model_id
    if [[ -z "$model_id" || "$model_id" == "null" ]]; then
        log_message "ERROR" "Invalid model ID: $model_id"
        return 1
    fi
    
    # Validate that model_id is a number
    if ! [[ "$model_id" =~ ^[0-9]+$ ]]; then
        log_message "ERROR" "Model ID is not a valid number: '$model_id'"
        return 1
    fi
    
    log_message "DEBUG" "Using model ID: $model_id"
    
    # Handle empty values for JSON
    local company_json="null"
    [[ -n "$company_id" && "$company_id" != "null" ]] && company_json="$company_id"
    
    local location_json="null"
    [[ -n "$location_id" && "$location_id" != "null" ]] && location_json="$location_id"
    
    local department_json="null"
    [[ -n "$department_id" && "$department_id" != "null" ]] && department_json="$department_id"
    
    local supplier_json="null"
    [[ -n "$supplier_id" && "$supplier_id" != "null" ]] && supplier_json="$supplier_id"
    
    # Build JSON for asset
    local asset_data=$(cat << EOF
{
    "name": "$ASSET_NAME",
    "model_id": $model_id,
    "status_id": 1,
    "asset_tag": "$ASSET_TAG",
    "company_id": $company_json,
    "location_id": $location_json,
    "department_id": $department_json,
    "supplier_id": $supplier_json,
    "purchase_date": "$PURCHASE_DATE",
    "warranty_months": $WARRANTY_MONTHS,
    "order_number": "$ORDER_NUMBER",
    "invoice_number": "$INVOICE_NUMBER",
    "next_audit_date": "$AUDIT_DATE",
    "expected_checkin": "$EXPECTED_CHECKIN_DATE",
    "custom_fields": {
        "$DISKS_COLUMN": "$DISKS",
        "$MEMORY_COLUMN": $MEMORY,
        "$VCPU_COLUMN": $VCPU,
        "$HOSTNAME_COLUMN": "$HOSTNAME",
        "$IP_COLUMN": "$IP_ADDRESS",
        "$OS_COLUMN": "$OS",
        "$SOFTWARE_COLUMN": "$SOFTWARE"
    }
}
EOF
)
    
    # Validate JSON before sending
    if ! echo "$asset_data" | jq . >/dev/null 2>&1; then
        log_message "ERROR" "Invalid JSON generated:"
        log_message "ERROR" "$asset_data"
        return 1
    fi
    
    log_message "DEBUG" "Asset data to create: $asset_data"
    
    local response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$asset_data" \
        "$SNIPEIT_SERVER/api/v1/hardware")
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n -1)
    
    # According to Snipe-IT API docs, they return 200 even on errors
    if [[ $http_code -eq 200 ]]; then
        # Check if the response indicates success or error
        local status=$(echo "$response_body" | jq -r '.status // empty')
        if [[ "$status" == "success" ]]; then
            local asset_id=$(echo "$response_body" | jq -r '.payload.id // empty')
            log_message "SUCCESS" "Asset created successfully - ID: $asset_id"
            return 0
        else
            log_message "ERROR" "API returned error status: $status"
            log_message "ERROR" "Response: $response_body"
            return 1
        fi
    elif [[ $http_code -eq 201 ]]; then
        local asset_id=$(echo "$response_body" | jq -r '.id // empty')
        log_message "SUCCESS" "Asset created successfully - ID: $asset_id"
        return 0
    else
        log_message "ERROR" "Error creating asset - HTTP Code: $http_code"
        log_message "ERROR" "Response: $response_body"
        return 1
    fi
}

# Function to detect system information
detect_system_info() {
    log_message "INFO" "Detecting system information..."
    
    # Detect CPU cores
    if [[ -z "$VCPU" || "$VCPU" == "0" ]]; then
        if command -v nproc >/dev/null 2>&1; then
            VCPU=$(nproc)
            log_message "INFO" "Detected CPU cores: $VCPU"
        elif [[ -f /proc/cpuinfo ]]; then
            VCPU=$(grep -c processor /proc/cpuinfo)
            log_message "INFO" "Detected CPU cores: $VCPU"
        else
            VCPU="1"
            log_message "WARNING" "Unable to detect CPU cores, using default: 1"
        fi
    fi
    
    # Detect memory (in GB)
    if [[ -z "$MEMORY" || "$MEMORY" == "0" ]]; then
        if command -v free >/dev/null 2>&1; then
            local mem_kb=$(free | grep Mem | awk '{print $2}')
            MEMORY=$((mem_kb / 1024 / 1024))
            log_message "INFO" "Detected memory: ${MEMORY}GB"
        elif [[ -f /proc/meminfo ]]; then
            local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            MEMORY=$((mem_kb / 1024 / 1024))
            log_message "INFO" "Detected memory: ${MEMORY}GB"
        else
            MEMORY="1"
            log_message "WARNING" "Unable to detect memory, using default: 1GB"
        fi
    fi
    
    # Detect disk information
    if [[ -z "$DISKS" ]]; then
        if command -v lsblk >/dev/null 2>&1; then
            DISKS=$(lsblk -d -o NAME,SIZE,TYPE | grep -E "(disk|loop)" | awk '{print $1 ": " $2}' | tr '\n' ', ' | sed 's/, $//')
            log_message "INFO" "Detected disks: $DISKS"
        elif command -v df >/dev/null 2>&1; then
            DISKS=$(df -h / | tail -1 | awk '{print $1 ": " $2}')
            log_message "INFO" "Detected disk: $DISKS"
        else
            DISKS="Unknown"
            log_message "WARNING" "Unable to detect disk information"
        fi
    fi
    
    # Detect operating system
    if [[ -z "$OS" ]]; then
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            OS="$NAME $VERSION"
            log_message "INFO" "Detected OS: $OS"
        elif [[ -f /etc/redhat-release ]]; then
            OS=$(cat /etc/redhat-release)
            log_message "INFO" "Detected OS: $OS"
        elif [[ -f /etc/debian_version ]]; then
            OS="Debian $(cat /etc/debian_version)"
            log_message "INFO" "Detected OS: $OS"
        else
            OS="Unknown"
            log_message "WARNING" "Unable to detect OS"
        fi
    fi
    
    # Detect IP address
    if [[ -z "$IP_ADDRESS" ]]; then
        if command -v ip >/dev/null 2>&1; then
            IP_ADDRESS=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
            log_message "INFO" "Detected IP address: $IP_ADDRESS"
        elif command -v hostname >/dev/null 2>&1; then
            IP_ADDRESS=$(hostname -I | awk '{print $1}')
            log_message "INFO" "Detected IP address: $IP_ADDRESS"
        else
            IP_ADDRESS=""
            log_message "WARNING" "Unable to detect IP address"
        fi
    fi
    
    # Detect hostname if not provided
    if [[ -z "$HOSTNAME" ]]; then
        if command -v hostname >/dev/null 2>&1; then
            HOSTNAME=$(hostname)
            log_message "INFO" "Detected hostname: $HOSTNAME"
        else
            HOSTNAME=""
            log_message "WARNING" "Unable to detect hostname"
        fi
    fi
    
    # Detect installed software
    if [[ -z "$SOFTWARE" ]]; then
        local software_list=""
        
        # Detect package manager and list installed packages
        if command -v dpkg >/dev/null 2>&1; then
            # Debian/Ubuntu systems
            software_list=$(dpkg -l | grep '^ii' | awk '{print $2 " " $3}' | head -20 | tr '\n' ', ' | sed 's/, $//')
            log_message "INFO" "Detected software (Debian/Ubuntu): $software_list"
        elif command -v rpm >/dev/null 2>&1; then
            # Red Hat/CentOS systems
            software_list=$(rpm -qa --queryformat '%{NAME}-%{VERSION}\n' | head -20 | tr '\n' ', ' | sed 's/, $//')
            log_message "INFO" "Detected software (Red Hat/CentOS): $software_list"
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux systems
            software_list=$(pacman -Q | head -20 | tr '\n' ', ' | sed 's/, $//')
            log_message "INFO" "Detected software (Arch): $software_list"
        else
            software_list="Unknown package manager"
            log_message "WARNING" "Unable to detect installed software"
        fi
        
        if [[ -n "$software_list" ]]; then
            SOFTWARE="$software_list"
        fi
    fi
}

# Main function
main() {
    log_message "INFO" "Starting SnipeIT asset creation script"
    
    # Detect operating system
    detect_os
    
    # Validate parameters
    validate_required_params
    validate_server_url
    
    # Set default asset name if not provided
    set_default_asset_name
    
    # Detect system information (unless disabled)
    if [[ "$NO_AUTO_DETECT" != "true" ]]; then
        detect_system_info
    else
        log_message "INFO" "Auto-detection disabled, using provided values only"
    fi
    
    # Calculate dates
    calculate_dates
    
    # Get custom field column names
    get_custom_field_columns
    
    # Check if asset exists
    local existing_asset_id
    if existing_asset_id=$(check_asset_exists "$ASSET_TAG" "$ASSET_NAME"); then
        if [[ "$FORCE_UPDATE" == "true" ]]; then
            log_message "INFO" "Asset already exists. Force update enabled, updating custom fields..."
            
            # Detect system information (unless disabled) for update
            if [[ "$NO_AUTO_DETECT" != "true" ]]; then
                detect_system_info
            fi
            
            # Update custom fields
            if update_asset_custom_fields "$existing_asset_id"; then
                log_message "SUCCESS" "Asset custom fields updated successfully"
                exit 0
            else
                log_message "ERROR" "Failed to update asset custom fields"
                exit 1
            fi
        else
            log_message "WARNING" "Asset already exists. Use --force-update to update custom fields."
            log_message "INFO" "Stopping script. Asset ID: $existing_asset_id"
            exit 0
        fi
    fi
    
    # Get model ID
    local model_id
    model_id=$(get_model_id "$MODEL_NAME")
    if [[ $? -ne 0 || -z "$model_id" ]]; then
        log_message "ERROR" "Unable to get model ID for: $MODEL_NAME"
        exit 1
    fi
    
    log_message "INFO" "Using model ID: $model_id"
    
    # Get other IDs
    local company_id=$(get_company_id)
    local location_id=$(get_location_id)
    local department_id=$(get_department_id)
    local supplier_id=$(get_supplier_id)
    
    # Create asset with explicit model_id
    if create_asset "$model_id" "$company_id" "$location_id" "$department_id" "$supplier_id"; then
        log_message "SUCCESS" "Asset created successfully in SnipeIT"
        exit 0
    else
        log_message "ERROR" "Failed to create asset"
        exit 1
    fi
}

# Global variables
SNIPEIT_SERVER=""
API_TOKEN=""
MODEL_NAME=""
ASSET_NAME=""
ASSET_TAG=""
COMPANY_NAME=""
LOCATION_NAME=""
DEPARTMENT_NAME=""
SUPPLIER_NAME=""
PURCHASE_DATE=""
WARRANTY_MONTHS=""
ORDER_NUMBER=""
INVOICE_NUMBER=""
DISKS=""
MEMORY=""
VCPU=""
HOSTNAME=""
IP_ADDRESS=""
OS=""
SOFTWARE=""
VERBOSE="false"
AUTO_INSTALL="false"
NO_AUTO_DETECT="false"
FORCE_UPDATE="false"

# Custom field column names (will be populated by get_custom_field_columns)
DISKS_COLUMN=""
MEMORY_COLUMN=""
VCPU_COLUMN=""
HOSTNAME_COLUMN=""
IP_COLUMN=""
OS_COLUMN=""
SOFTWARE_COLUMN=""

# Argument processing
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--server)
            SNIPEIT_SERVER="$2"
            shift 2
            ;;
        -t|--token)
            API_TOKEN="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_NAME="$2"
            shift 2
            ;;
        -n|--name)
            ASSET_NAME="$2"
            shift 2
            ;;
        -a|--asset-tag)
            ASSET_TAG="$2"
            shift 2
            ;;
        -c|--company)
            COMPANY_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION_NAME="$2"
            shift 2
            ;;
        -d|--department)
            DEPARTMENT_NAME="$2"
            shift 2
            ;;
        -u|--supplier)
            SUPPLIER_NAME="$2"
            shift 2
            ;;
        -p|--purchase-date)
            PURCHASE_DATE="$2"
            shift 2
            ;;
        -w|--warranty-months)
            WARRANTY_MONTHS="$2"
            shift 2
            ;;
        -o|--order-number)
            ORDER_NUMBER="$2"
            shift 2
            ;;
        -i|--invoice-number)
            INVOICE_NUMBER="$2"
            shift 2
            ;;
        --disks)
            DISKS="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --vcpu)
            VCPU="$2"
            shift 2
            ;;
        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;
        --ip-address)
            IP_ADDRESS="$2"
            shift 2
            ;;
        --os)
            OS="$2"
            shift 2
            ;;
        --software)
            SOFTWARE="$2"
            shift 2
            ;;
        --auto-install)
            AUTO_INSTALL="true"
            shift
            ;;
        --no-auto-detect)
            NO_AUTO_DETECT="true"
            shift
            ;;
        --force-update)
            FORCE_UPDATE="true"
            shift
            ;;
        -v|--verbose)
            VERBOSE="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_message "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Dependency checking and installation
if [[ "$AUTO_INSTALL" == "true" ]]; then
    install_dependencies
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to install dependencies automatically"
        log_message "INFO" "Please install manually:"
        log_message "INFO" "  - On Debian/Ubuntu: sudo apt-get install curl jq"
        log_message "INFO" "  - On CentOS/RHEL: sudo yum install curl jq"
        log_message "INFO" "  - On Fedora: sudo dnf install curl jq"
        exit 1
    fi
else
    # Simple dependency checking
    missing_deps=()
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_message "ERROR" "Missing dependencies: ${missing_deps[*]}"
        log_message "INFO" "Use the --auto-install option to install automatically"
        log_message "INFO" "Or install manually:"
        log_message "INFO" "  - On Debian/Ubuntu: sudo apt-get install curl jq"
        log_message "INFO" "  - On CentOS/RHEL: sudo yum install curl jq"
        log_message "INFO" "  - On Fedora: sudo dnf install curl jq"
        exit 1
    fi
fi

# Default values for optional fields
[[ -z "$ASSET_TAG" ]] && ASSET_TAG=""
[[ -z "$COMPANY_NAME" ]] && COMPANY_NAME=""
[[ -z "$LOCATION_NAME" ]] && LOCATION_NAME=""
[[ -z "$DEPARTMENT_NAME" ]] && DEPARTMENT_NAME=""
[[ -z "$SUPPLIER_NAME" ]] && SUPPLIER_NAME=""
[[ -z "$PURCHASE_DATE" ]] && PURCHASE_DATE=""
[[ -z "$WARRANTY_MONTHS" ]] && WARRANTY_MONTHS="0"
[[ -z "$ORDER_NUMBER" ]] && ORDER_NUMBER=""
[[ -z "$INVOICE_NUMBER" ]] && INVOICE_NUMBER=""
[[ -z "$DISKS" ]] && DISKS=""
[[ -z "$MEMORY" ]] && MEMORY="0"
[[ -z "$VCPU" ]] && VCPU="0"
[[ -z "$HOSTNAME" ]] && HOSTNAME=""
[[ -z "$IP_ADDRESS" ]] && IP_ADDRESS=""
[[ -z "$OS" ]] && OS=""
[[ -z "$SOFTWARE" ]] && SOFTWARE=""

# Validate numeric fields
if [[ -n "$MEMORY" && ! "$MEMORY" =~ ^[0-9]+$ ]]; then
    log_message "ERROR" "Memory must be a numeric value"
    exit 1
fi

if [[ -n "$VCPU" && ! "$VCPU" =~ ^[0-9]+$ ]]; then
    log_message "ERROR" "vCPU must be a numeric value"
    exit 1
fi

if [[ -n "$WARRANTY_MONTHS" && ! "$WARRANTY_MONTHS" =~ ^[0-9]+$ ]]; then
    log_message "ERROR" "Warranty months must be a numeric value"
    exit 1
fi

# Execute main script
main "$@"
