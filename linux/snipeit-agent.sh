#!/bin/bash

# SnipeIT Asset Creation Script
# Script to create assets in SnipeIT with custom fields management
# Compatible with all Linux systems

set -e  # Stop script on error

# Colors for messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to escape JSON strings
escape_json_string() {
    local string="$1"
    # Escape backslashes, quotes, and convert newlines to \n
    echo "$string" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/\r/\\r/g' | sed 's/\t/\\t/g'
}

# Function to detect system information
detect_system_info() {
    log_message "INFO" "Detecting system information..."
    
    # Detect CPU cores
    if [[ -z "$VCPU" || "$VCPU" == "0" ]]; then
        if command -v nproc >/dev/null 2>&1; then
            VCPU=$(nproc)
            log_message "DEBUG" "Detected CPU cores: $VCPU"
        elif [[ -f /proc/cpuinfo ]]; then
            VCPU=$(grep -c processor /proc/cpuinfo)
            log_message "DEBUG" "Detected CPU cores: $VCPU"
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
            log_message "DEBUG" "Detected memory: ${MEMORY}GB"
        elif [[ -f /proc/meminfo ]]; then
            local mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            MEMORY=$((mem_kb / 1024 / 1024))
            log_message "DEBUG" "Detected memory: ${MEMORY}GB"
        else
            MEMORY="1"
            log_message "WARNING" "Unable to detect memory, using default: 1GB"
        fi
    fi
    
    # Detect disk information
    if [[ -z "$DISKS" ]]; then
        if command -v lsblk >/dev/null 2>&1; then
            DISKS=$(lsblk -d -o NAME,SIZE,TYPE | grep -E "(disk|loop)" | awk '{print $1 ": " $2}' | tr '\n' ', ' | sed 's/, $//')
            log_message "DEBUG" "Detected disks: $DISKS"
        elif command -v df >/dev/null 2>&1; then
            DISKS=$(df -h / | tail -1 | awk '{print $1 ": " $2}')
            log_message "DEBUG" "Detected disk: $DISKS"
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
            log_message "DEBUG" "Detected OS: $OS"
        elif [[ -f /etc/redhat-release ]]; then
            OS=$(cat /etc/redhat-release)
            log_message "DEBUG" "Detected OS: $OS"
        elif [[ -f /etc/debian_version ]]; then
            OS="Debian $(cat /etc/debian_version)"
            log_message "DEBUG" "Detected OS: $OS"
        else
            OS="Unknown"
            log_message "WARNING" "Unable to detect OS"
        fi
    fi
    
    # Detect IP address
    if [[ -z "$IP_ADDRESS" ]]; then
        if command -v ip >/dev/null 2>&1; then
            IP_ADDRESS=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+' | head -1)
            log_message "DEBUG" "Detected IP address: $IP_ADDRESS"
        elif command -v hostname >/dev/null 2>&1; then
            IP_ADDRESS=$(hostname -I | awk '{print $1}')
            log_message "DEBUG" "Detected IP address: $IP_ADDRESS"
        else
            IP_ADDRESS=""
            log_message "WARNING" "Unable to detect IP address"
        fi
    fi
    
    # Detect hostname if not provided
    if [[ -z "$HOSTNAME" ]]; then
        if command -v hostname >/dev/null 2>&1; then
            HOSTNAME=$(hostname)
            log_message "DEBUG" "Detected hostname: $HOSTNAME"
        else
            HOSTNAME=""
            log_message "WARNING" "Unable to detect hostname"
        fi
    fi
    
    # Detect installed software (improved formatting for JSON compatibility)
    if [[ -z "$SOFTWARE" ]]; then
        local software_list=""
        
        # Detect package manager and list installed packages
        if command -v dpkg >/dev/null 2>&1; then
            # Debian/Ubuntu systems - format as app (version)
            software_list=$(dpkg -l | grep '^ii' | awk '{print $2 " (" $3 ")"}' | paste -sd '|' - | sed 's/|/, /g')
            log_message "DEBUG" "Detected software (Debian/Ubuntu): $software_list"
        elif command -v rpm >/dev/null 2>&1; then
            # Red Hat/CentOS systems - format as app (version)
            software_list=$(rpm -qa --queryformat '%{NAME} (%{VERSION})\n' | head -20 | paste -sd ", " -)
            log_message "DEBUG" "Detected software (Red Hat/CentOS): $software_list"
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux systems - format as app (version)
            software_list=$(pacman -Q | awk '{print $1 " (" $2 ")"}' | head -20 | paste -sd ", " -)
            log_message "DEBUG" "Detected software (Arch): $software_list"
        else
            software_list="Unknown package manager"
            log_message "WARNING" "Unable to detect installed software"
        fi
        
        if [[ -n "$software_list" ]]; then
            SOFTWARE="$software_list"
        fi
    fi
}

# Function to get custom field column names
get_custom_field_columns() {
    log_message "DEBUG" "Getting custom field column names..."
    
    local response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/fields")
    
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Error getting custom fields, using default column names"
        return 1
    fi
    
    log_message "DEBUG" "Custom fields API response: $response"
    
    # Try different response formats
    local fields_json=""
    
    # Try .rows format first
    fields_json=$(echo "$response" | jq -r '.rows // empty')
    if [[ -n "$fields_json" && "$fields_json" != "null" ]]; then
        log_message "DEBUG" "Found custom fields in .rows format"
    else
        # Try direct array format
        fields_json=$(echo "$response" | jq -r '. // empty')
        if [[ -n "$fields_json" && "$fields_json" != "null" ]]; then
            log_message "DEBUG" "Found custom fields in direct array format"
        else
            # Try .data format
            fields_json=$(echo "$response" | jq -r '.data // empty')
            if [[ -n "$fields_json" && "$fields_json" != "null" ]]; then
                log_message "DEBUG" "Found custom fields in .data format"
            else
                log_message "WARNING" "No custom fields found in any format, using default column names"
                return 1
            fi
        fi
    fi
    
    # Check if fields_json is an array
    local is_array=$(echo "$fields_json" | jq -r 'if type == "array" then "true" else "false" end')
    if [[ "$is_array" != "true" ]]; then
        log_message "WARNING" "Custom fields response is not an array, using default column names"
        return 1
    fi
    
    # List all available custom fields for debugging
    log_message "DEBUG" "Available custom fields:"
    log_message "DEBUG" "$fields_json" | jq -r '.[] | "  - \(.name) (db_column: \(.db_column_name // "null"))"' >&2
    
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

# Function to check if asset already exists
check_asset_exists() {
    local asset_tag="$1"
    local asset_name="$2"
    
    log_message "DEBUG" "Checking if asset exists"
    
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
        # Store the ID in a global variable to avoid printf issues
        ASSET_ID_TO_UPDATE="$existing_id"
        return 0
    fi
    
    log_message "DEBUG" "No existing asset found"
    return 1
}

# Function to get model ID
get_model_id() {
    local model_name="$1"
    
    # Log to stderr to avoid interfering with return value
    log_message "DEBUG" "Getting model ID: $model_name" >&2
    
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
    
    # Log success to stderr
    log_message "DEBUG" "Model found: $model_name (ID: $model_id)" >&2
    
    # Return only the clean model ID to stdout
    printf "%s" "$model_id"
}

# Function to update asset custom fields
update_asset_custom_fields() {
    local asset_id="$1"
    
    log_message "INFO" "Updating custom fields for asset ID: $asset_id"
    
    # First, get current asset data to preserve existing custom fields
    log_message "DEBUG" "Retrieving current asset data..."
    local current_response=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        "$SNIPEIT_SERVER/api/v1/hardware/$asset_id")
    
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to retrieve current asset data"
        return 1
    fi
    
    local current_asset=$(echo "$current_response" | jq -r '. // empty')
    if [[ -z "$current_asset" || "$current_asset" == "null" ]]; then
        log_message "ERROR" "Invalid response when retrieving current asset data"
        return 1
    fi
    
    log_message "DEBUG" "Current asset data retrieved successfully"
    
    # Extract existing custom field values to preserve them
    local existing_disks=$(echo "$current_asset" | jq -r ".$DISKS_COLUMN // empty")
    local existing_memory=$(echo "$current_asset" | jq -r ".$MEMORY_COLUMN // empty")
    local existing_vcpu=$(echo "$current_asset" | jq -r ".$VCPU_COLUMN // empty")
    local existing_hostname=$(echo "$current_asset" | jq -r ".$HOSTNAME_COLUMN // empty")
    local existing_ip=$(echo "$current_asset" | jq -r ".$IP_COLUMN // empty")
    local existing_os=$(echo "$current_asset" | jq -r ".$OS_COLUMN // empty")
    local existing_software=$(echo "$current_asset" | jq -r ".$SOFTWARE_COLUMN // empty")
    
    # Use new values if provided, otherwise keep existing values
    local final_disks="${DISKS:-$existing_disks}"
    local final_memory="${MEMORY:-$existing_memory}"
    local final_vcpu="${VCPU:-$existing_vcpu}"
    local final_hostname="${HOSTNAME:-$existing_hostname}"
    local final_ip="${IP_ADDRESS:-$existing_ip}"
    local final_os="${OS:-$existing_os}"
    local final_software="${SOFTWARE:-$existing_software}"
    
    # Escape custom field values for JSON
    local escaped_disks=$(escape_json_string "$final_disks")
    local escaped_hostname=$(escape_json_string "$final_hostname")
    local escaped_ip=$(escape_json_string "$final_ip")
    local escaped_os=$(escape_json_string "$final_os")
    local escaped_software=$(escape_json_string "$final_software")
    
    # Build JSON for custom fields update - only include fields we actually use
    local update_data=$(cat << EOF
{
    "$DISKS_COLUMN": "$escaped_disks",
    "$MEMORY_COLUMN": $final_memory,
    "$VCPU_COLUMN": $final_vcpu,
    "$HOSTNAME_COLUMN": "$escaped_hostname",
    "$IP_COLUMN": "$escaped_ip",
    "$OS_COLUMN": "$escaped_os",
    "$SOFTWARE_COLUMN": "$escaped_software"
}
EOF
)
    
    # Validate JSON before sending
    if ! echo "$update_data" | jq . >/dev/null 2>&1; then
        log_message "ERROR" "Invalid JSON generated for asset update:"
        log_message "ERROR" "$update_data"
        return 1
    fi
    
    log_message "DEBUG" "Asset update data: $update_data"
    
    local response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -X PATCH \
        -d "$update_data" \
        "$SNIPEIT_SERVER/api/v1/hardware/$asset_id" 2>&1)
    
    local curl_exit_code=$?
    
    if [[ $curl_exit_code -ne 0 ]]; then
        log_message "ERROR" "Curl command failed with exit code: $curl_exit_code"
        log_message "ERROR" "Curl error output: $response"
        return 1
    fi
    
    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | head -n -1)
    
    log_message "DEBUG" "Update response HTTP code: $http_code"
    log_message "DEBUG" "Update response body: $response_body"
    
    if [[ $http_code -eq 200 ]]; then
        local status=$(echo "$response_body" | jq -r '.status // empty')
        if [[ "$status" == "success" ]]; then
            log_message "SUCCESS" "Asset custom fields updated successfully"
            return 0
        else
            local error_message=$(echo "$response_body" | jq -r '.messages // .message // "Unknown error"')
            log_message "ERROR" "API returned error status: $status"
            log_message "ERROR" "Error message: $error_message"
            return 1
        fi
    elif [[ $http_code -eq 201 ]]; then
        log_message "SUCCESS" "Asset custom fields updated successfully"
        return 0
    else
        log_message "ERROR" "Error updating asset custom fields - HTTP Code: $http_code"
        log_message "ERROR" "Response: $response_body"
        return 1
    fi
}

# Function to create asset
create_asset() {
    local model_id="$1"
    
    log_message "INFO" "Creating asset: $ASSET_NAME"
    
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
    
    # Calculate dates
    local next_audit_date=$(date -d '+1 year' '+%Y-%m-%d' 2>/dev/null || date -v+1y '+%Y-%m-%d' 2>/dev/null || date '+%Y-%m-%d')
    
    log_message "DEBUG" "Next Audit Date: $next_audit_date"
    
    # Escape custom field values for JSON
    local escaped_disks=$(escape_json_string "$DISKS")
    local escaped_hostname=$(escape_json_string "$HOSTNAME")
    local escaped_ip=$(escape_json_string "$IP_ADDRESS")
    local escaped_os=$(escape_json_string "$OS")
    local escaped_software=$(escape_json_string "$SOFTWARE")
    local escaped_asset_name=$(escape_json_string "$ASSET_NAME")
    local escaped_asset_tag=$(escape_json_string "$ASSET_TAG")
    
    # Build JSON for asset
    local asset_data=$(cat << EOF
{
    "name": "$escaped_asset_name",
    "model_id": $model_id,
    "status_id": 2,
    "asset_tag": "$escaped_asset_tag",
    "next_audit_date": "$next_audit_date",
    "$DISKS_COLUMN": "$escaped_disks",
    "$MEMORY_COLUMN": $MEMORY,
    "$VCPU_COLUMN": $VCPU,
    "$HOSTNAME_COLUMN": "$escaped_hostname",
    "$IP_COLUMN": "$escaped_ip",
    "$OS_COLUMN": "$escaped_os",
    "$SOFTWARE_COLUMN": "$escaped_software"
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
    
    if [[ $http_code -eq 200 ]]; then
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

# Function to display help messages
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Script to create assets in SnipeIT with custom fields management

OPTIONS:
    -s, --server URL        SnipeIT server URL (required)
    -t, --token TOKEN       SnipeIT API token (required)
    -m, --model MODEL       Asset model name (required)
    -n, --name NAME         Asset name (optional, defaults to hostname)
    -a, --asset-tag TAG     Asset tag (optional)
    --hostname HOSTNAME     Hostname (text)
    --ip-address IP         IP address (text)
    --os OS                 Operating system (text)
    --memory MEMORY         Memory in GB (numeric)
    --vcpu VCPU             vCPU (numeric)
    --disks DISKS           Disk(s) (textarea)
    --software SOFTWARE     Software (textarea)
    --no-auto-detect        Disable automatic system information detection
    -v, --verbose           Verbose mode
    -h, --help             Show this help

AUTO-DETECTION:
    The script automatically detects system information if not provided:
    - CPU cores (vCPU)
    - Memory (RAM) in GB
    - Disk information
    - Operating system
    - IP address
    - Hostname
    - Installed software with version

EXAMPLES:
    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "VM Linux" --hostname "server01.company.com" --ip-address "192.168.1.100"

    $0 -s "https://snipeit.company.com" -t "your-api-token" -m "VM Linux" --no-auto-detect

EOF
}

# Main function
main() {
    log_message "INFO" "Starting SnipeIT asset creation script"
    
    # Validate parameters
    if [[ -z "$SNIPEIT_SERVER" || -z "$API_TOKEN" || -z "$MODEL_NAME" ]]; then
        log_message "ERROR" "Missing required parameters: server, token, or model"
        echo
        show_help
        exit 1
    fi
    
    # Validate server URL
    if [[ ! "$SNIPEIT_SERVER" =~ ^https?:// ]]; then
        log_message "ERROR" "Server URL must start with http:// or https://"
        exit 1
    fi
    
    # Remove trailing slash if exists
    SNIPEIT_SERVER=${SNIPEIT_SERVER%/}
    
    # Set default asset name based on hostname
    if [[ -z "$ASSET_NAME" ]]; then
        if [[ -n "$HOSTNAME" ]]; then
            ASSET_NAME="$HOSTNAME"
            log_message "DEBUG" "Using hostname as asset name: $ASSET_NAME"
        else
            # Try to get hostname from system
            local system_hostname=$(hostname 2>/dev/null || echo "")
            if [[ -n "$system_hostname" ]]; then
                ASSET_NAME="$system_hostname"
                log_message "DEBUG" "Using system hostname as asset name: $ASSET_NAME"
            else
                log_message "ERROR" "No asset name provided and unable to determine hostname"
                log_message "INFO" "Please provide an asset name with --name option or hostname with --hostname option"
                exit 1
            fi
        fi
    fi
    
    # Detect system information (unless disabled)
    if [[ "$NO_AUTO_DETECT" != "true" ]]; then
        detect_system_info
    else
        log_message "DEBUG" "Auto-detection disabled, using provided values only"
    fi
    
    # Get custom field column names
    get_custom_field_columns
    
    # Check if asset exists
    if check_asset_exists "$ASSET_TAG" "$ASSET_NAME"; then
        log_message "INFO" "Asset already exists. Updating custom fields..."
        
        # Update custom fields
        if update_asset_custom_fields "$ASSET_ID_TO_UPDATE"; then
            log_message "SUCCESS" "Asset custom fields updated successfully"
            exit 0
        else
            log_message "ERROR" "Failed to update asset custom fields"
            exit 1
        fi
    fi
    
    # Get model ID
    local model_id
    model_id=$(get_model_id "$MODEL_NAME")
    if [[ $? -ne 0 || -z "$model_id" ]]; then
        log_message "ERROR" "Unable to get model ID for: $MODEL_NAME"
        exit 1
    fi
    
    log_message "DEBUG" "Using model ID: $model_id"
    
    # Create asset
    if create_asset "$model_id"; then
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
DISKS=""
MEMORY=""
VCPU=""
HOSTNAME=""
IP_ADDRESS=""
OS=""
SOFTWARE=""
VERBOSE="false"
AUTO_DETECT="false"
NO_AUTO_DETECT="false"
ASSET_ID_TO_UPDATE=""

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
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --vcpu)
            VCPU="$2"
            shift 2
            ;;
        --disks)
            DISKS="$2"
            shift 2
            ;;
        --software)
            SOFTWARE="$2"
            shift 2
            ;;
        --no-auto-detect)
            NO_AUTO_DETECT="true"
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

# Execute main script
main "$@"
