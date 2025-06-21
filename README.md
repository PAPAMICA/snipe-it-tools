# snipe-it-tools
Scripts for SnipeIT

## Available Scripts

### Bash Scripts (directory `linux/`)

#### `linux/snipeit-agent.sh` - SnipeIT Asset Creation

Bash script to create assets in SnipeIT with custom fields management.

#### Features

- ✅ Asset creation with "Pending" status
- ✅ Automatic date management (audit in 1 year, check-in in 2 days)
- ✅ Custom fields support:
  - Disk(s) (textarea)
  - Memory in GB (numeric)
  - vCPU (numeric)
  - Hostname (text)
  - IP address (text)
  - OS (text)
  - Software (textarea)
- ✅ Asset existence check before creation
- ✅ Automatic ID retrieval (model, company, location, etc.)
- ✅ Colored and detailed logging
- ✅ Robust error handling
- ✅ Modular and extensible architecture
- ✅ Multi-OS compatibility (Debian, CentOS, Ubuntu, RHEL, etc.)

#### Prerequisites

- `curl` for API calls
- `jq` for JSON parsing
- SnipeIT API token with write permissions

#### Automatic Dependency Installation

The script can automatically install dependencies on all Linux distributions:

```bash
./linux/snipeit-agent.sh --auto-install [OTHER_OPTIONS]
```

#### Manual Dependency Installation

**On CentOS/RHEL:**
```bash
sudo yum install curl jq
```

**On Ubuntu/Debian:**
```bash
sudo apt-get install curl jq
```

**On macOS:**
```bash
brew install curl jq
```

#### Usage

```bash
./linux/snipeit-agent.sh [OPTIONS]
```

##### Required Parameters

- `-s, --server URL` : SnipeIT server URL
- `-t, --token TOKEN` : SnipeIT API token
- `-m, --model MODEL` : Asset model name
- `-n, --name NAME` : Asset name

##### Optional Parameters

- `-a, --asset-tag TAG` : Asset tag
- `-c, --company COMPANY` : Company name
- `-l, --location LOCATION` : Location name
- `-d, --department DEPT` : Department name
- `-u, --supplier SUPPLIER` : Supplier name
- `-p, --purchase-date DATE` : Purchase date (YYYY-MM-DD)
- `-w, --warranty-months MONTHS` : Warranty months
- `-o, --order-number ORDER` : Order number
- `-i, --invoice-number INVOICE` : Invoice number

##### Custom Fields

- `--disks DISKS` : Disk(s) (textarea)
- `--memory MEMORY` : Memory in GB (numeric)
- `--vcpu VCPU` : vCPU (numeric)
- `--hostname HOSTNAME` : Hostname (text)
- `--ip-address IP` : IP address (text)
- `--os OS` : Operating system (text)
- `--software SOFTWARE` : Software (textarea)

##### General Options

- `--auto-install` : Automatic dependency installation (curl, jq)
- `-v, --verbose` : Verbose mode
- `-h, --help` : Show help

#### Usage Examples

**Create a desktop PC:**
```bash
./linux/snipeit-agent.sh \
  -s "https://snipeit.company.com" \
  -t "your-api-token" \
  -m "Dell OptiPlex 7090" \
  -n "PC-001" \
  --hostname "pc001.company.com" \
  --ip-address "192.168.1.100" \
  --memory 16 \
  --vcpu 8 \
  --os "Ubuntu 22.04" \
  --disks "SSD 512GB" \
  --software "Office 365, Chrome, Firefox"
```

**Create a laptop:**
```bash
./linux/snipeit-agent.sh \
  -s "https://snipeit.company.com" \
  -t "your-api-token" \
  -m "HP ProBook 450" \
  -n "LAPTOP-001" \
  --hostname "laptop001.company.com" \
  --ip-address "192.168.1.101" \
  --memory 32 \
  --vcpu 16 \
  --os "Windows 11" \
  --disks "SSD 1TB" \
  --software "Office 365, Teams, Zoom"
```

**Create with complete information:**
```bash
./linux/snipeit-agent.sh \
  -s "https://snipeit.company.com" \
  -t "your-api-token" \
  -m "Dell PowerEdge R740" \
  -n "SRV-PROD-01" \
  -a "SRV001" \
  -c "My Company" \
  -l "Main Datacenter" \
  -d "IT Infrastructure" \
  -u "Dell Technologies" \
  -p "2024-01-15" \
  -w 36 \
  -o "PO-2024-001" \
  -i "INV-2024-001" \
  --hostname "srv-prod-01.company.com" \
  --ip-address "10.0.1.100" \
  --memory 128 \
  --vcpu 32 \
  --os "Ubuntu Server 22.04 LTS" \
  --disks "2x SSD 1TB RAID1, 4x HDD 4TB RAID5" \
  --software "Docker, Kubernetes, PostgreSQL, Redis"
```

**With automatic dependency installation:**
```bash
./linux/snipeit-agent.sh \
  -s "https://snipeit.company.com" \
  -t "your-api-token" \
  -m "Dell OptiPlex 7090" \
  -n "PC-001" \
  --auto-install
```

#### `linux/config.sh` - Default Configuration

Configuration file to simplify the use of the main script.

#### Features

- ✅ Centralized SnipeIT parameter configuration
- ✅ Predefined lists of models, locations, departments, etc.
- ✅ Utility functions for asset creation
- ✅ Automatic configuration validation

#### Usage

**Load configuration:**
```bash
source linux/config.sh
```

**Check configuration:**
```bash
./linux/config.sh --check
```

**Show common options:**
```bash
./linux/config.sh --show-options
```

**Show help:**
```bash
./linux/config.sh --help
```

#### Configuration

Edit the `linux/config.sh` file to define your parameters:

```bash
# SnipeIT server configuration
export SNIPEIT_SERVER="https://your-snipeit-server.com"
export API_TOKEN="your-api-token-here"

# Default configuration for assets
export DEFAULT_COMPANY="My Company"
export DEFAULT_LOCATION="Main Office"
export DEFAULT_DEPARTMENT="IT Infrastructure"
export DEFAULT_SUPPLIER="Dell Technologies"
```

#### Available functions after loading

```bash
# Show common options
show_common_options

# Check configuration
check_config

# Create an asset with default values
create_asset_with_defaults "Dell OptiPlex 7090" "PC-001" "pc001.company.com" "192.168.1.100" 16 8 "Ubuntu 22.04"
```

#### `linux/example-usage.sh` - Example Script

Interactive script to test and demonstrate the use of the main script.

#### Features

- ✅ Ready-to-use examples
- ✅ Automatic prerequisite checking
- ✅ Interactive mode with confirmation
- ✅ Different asset types (PC, laptop, server)

#### Usage

```bash
# First configure parameters in the script
# Then execute
./linux/example-usage.sh
```

#### Included Examples

1. **Simple Desktop PC** - Basic PC creation
2. **Laptop with Software** - Laptop with detailed software
3. **Complete Server** - Server with all information
4. **Verbose Mode** - Test with detailed output
5. **Help** - Display script help

#### `linux/install.sh` - Installation Script

Automated installation script to configure the SnipeIT Tools environment.

#### Features

- ✅ Automatic dependency installation (curl, jq)
- ✅ Interactive environment configuration
- ✅ Automatic operating system detection
- ✅ Configuration testing
- ✅ Support for CentOS/RHEL, Debian/Ubuntu and macOS

#### Usage

**Complete installation:**
```bash
./linux/install.sh --all
```

**Dependencies installation only:**
```bash
./linux/install.sh --install-deps
```

**Configuration only:**
```bash
./linux/install.sh --configure
```

**Configuration test:**
```bash
./linux/install.sh --test
```

**Show help:**
```bash
./linux/install.sh --help
```

#### Supported Systems

- **CentOS/RHEL** : Installation via yum/dnf
- **Debian/Ubuntu** : Installation via apt-get
- **macOS** : Installation via Homebrew

### Python Scripts (directory `tools/`)

#### `tools/list-settings.py` - SnipeIT Configuration Analyzer

Python script to test connection to SnipeIT server and list all available configurations.

#### Features

- ✅ SnipeIT server connection test
- ✅ Asset types and categories list
- ✅ Available models list
- ✅ Custom fields list
- ✅ Status labels list
- ✅ Companies, locations, departments list
- ✅ Suppliers and manufacturers list
- ✅ Available API endpoints display
- ✅ Configuration export to JSON format
- ✅ Colored user interface with Rich

#### Prerequisites

- Python 3.6+
- pip (Python package manager)
- SnipeIT API token with read permissions

#### Installation

**Automatic installation:**
```bash
cd tools
./install-python-deps.sh --all
```

**Manual installation:**
```bash
pip3 install requests rich
```

#### Usage

```bash
python3 tools/list-settings.py [OPTIONS]
```

##### Required Parameters

- `-s, --server URL` : SnipeIT server URL
- `-t, --token TOKEN` : SnipeIT API token

##### Display Options

- `--all` : Display all configurations
- `--categories` : List asset categories
- `--models` : List models
- `--custom-fields` : List custom fields
- `--status-labels` : List status labels
- `--companies` : List companies
- `--locations` : List locations
- `--departments` : List departments
- `--suppliers` : List suppliers
- `--manufacturers` : List manufacturers
- `--api-endpoints` : Display available API endpoints

##### Export Options

- `--export` : Export configuration to JSON format
- `--export-file FILE` : Export filename (default: snipeit_config.json)

#### Usage Examples

**Simple connection test:**
```bash
python3 tools/list-settings.py -s "https://snipeit.company.com" -t "your-api-token"
```

**List models and custom fields:**
```bash
python3 tools/list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --models --custom-fields
```

**Export configuration:**
```bash
python3 tools/list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --export --export-file "config.json"
```

**Display all information:**
```bash
python3 tools/list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --all
```

#### `tools/install-python-deps.sh` - Python Installation Script

Bash script to automate Python dependencies installation.

#### Features

- ✅ Python 3 verification
- ✅ pip verification
- ✅ Automatic dependency installation
- ✅ Installation testing
- ✅ Support for different operating systems

#### Usage

```bash
cd tools
./install-python-deps.sh [OPTIONS]
```

##### Options

- `-i, --install` : Install dependencies
- `-t, --test` : Test installation
- `-a, --all` : Complete installation + test
- `-h, --help` : Show help

#### Examples

```bash
# Complete installation
./install-python-deps.sh --all

# Installation only
./install-python-deps.sh --install

# Test only
./install-python-deps.sh --test
```

#### `tools/requirements.txt` - Python Dependencies

File listing required Python dependencies:

- `requests>=2.28.0` : For HTTP calls to SnipeIT API
- `rich>=12.0.0` : For colored display and tables

## Main Script Architecture

The script is designed in a modular way with the following functions:

- `show_help()` : Display help
- `log_message()` : Logging with colors and levels
- `validate_required_params()` : Validate required parameters
- `validate_server_url()` : Validate server URL
- `calculate_dates()` : Automatic date calculation
- `get_model_id()` : Get model ID
- `get_company_id()` : Get company ID
- `get_location_id()` : Get location ID
- `get_department_id()` : Get department ID
- `get_supplier_id()` : Get supplier ID
- `check_asset_exists()` : Check if asset exists
- `create_asset()` : Create asset
- `main()` : Main function orchestrating the process

## Extensibility

The script is designed to be easily extensible:

1. **New custom fields** : Add parameters and logic in `create_asset()`
2. **New entities** : Create similar `get_*_id()` functions
3. **New validations** : Add validation functions
4. **New statuses** : Modify `status_id` in `create_asset()`

## Error Handling

The script handles the following errors:
- Missing parameters
- Invalid server URL
- Model not found
- Asset already exists
- API connection errors
- Missing dependencies (curl, jq)

## Logging

The script uses a colored logging system with 5 levels:
- **INFO** (blue) : General information
- **SUCCESS** (green) : Successful operations
- **WARNING** (yellow) : Warnings
- **ERROR** (red) : Errors
- **DEBUG** (yellow) : Debug information (verbose mode)

## Security

- The script uses Bearer Token authentication
- Sensitive parameters are not displayed in debug mode
- URL and input parameter validation

## Quick Start

### Method 1: Automated Installation (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd snipe-it-tools

# Install bash scripts
cd linux
./install.sh --all

# Install Python tools
cd ../tools
./install-python-deps.sh --all
```

### Method 2: Manual Installation

1. **Install bash dependencies:**
   ```bash
   # On CentOS/RHEL
   sudo yum install curl jq
   
   # On Ubuntu/Debian
   sudo apt-get install curl jq
   
   # On macOS
   brew install curl jq
   ```

2. **Install Python dependencies:**
   ```bash
   pip3 install requests rich
   ```

3. **Configure environment:**
   ```bash
   # Edit bash configuration
   nano linux/config.sh
   
   # Load configuration
   source linux/config.sh
   ```

4. **Test with an example:**
   ```bash
   # Use bash examples script
   ./linux/example-usage.sh
   
   # Use Python script
   python3 tools/list-settings.py -s "https://your-snipeit-server.com" -t "your-api-token"
   
   # Create an asset directly
   ./linux/snipeit-agent.sh \
     -s "https://your-snipeit-server.com" \
     -t "your-api-token" \
     -m "Dell OptiPlex 7090" \
     -n "PC-TEST-001" \
     --hostname "pc-test.company.com" \
     --ip-address "192.168.1.200" \
     --memory 16 \
     --vcpu 8 \
     --os "Ubuntu 22.04"
   ```

## Project Structure

```
snipe-it-tools/
├── README.md                    # Main documentation
├── linux/                       # Bash scripts
│   ├── snipeit-agent.sh         # Main asset creation script
│   ├── config.sh                # Configuration file
│   ├── example-usage.sh         # Interactive examples script
│   └── install.sh               # Automated installation script
└── tools/                       # Python tools
    ├── list-settings.py         # SnipeIT configuration analyzer
    ├── install-python-deps.sh   # Python dependencies installation script
    ├── requirements.txt         # Python dependencies
    └── README.md                # Python tools documentation
```

## Usage Workflow

### Complete Workflow

1. **Installation** : Use installation scripts to configure environment
2. **Analysis** : Use `tools/list-settings.py` to analyze SnipeIT configuration
3. **Configuration** : Edit `linux/config.sh` with your parameters
4. **Test** : Use `linux/example-usage.sh` to test configuration
5. **Creation** : Create assets with `linux/snipeit-agent.sh`
6. **Verification** : Re-use `tools/list-settings.py` to verify creations

### Quick Workflow

```bash
# 1. Installation
cd linux && ./install.sh --all
cd ../tools && ./install-python-deps.sh --all

# 2. Configuration analysis
python3 tools/list-settings.py -s "URL" -t "TOKEN" --all

# 3. Configuration
source linux/config.sh

# 4. Asset creation
./linux/snipeit-agent.sh -s "URL" -t "TOKEN" -m "MODEL" -n "NAME" --hostname "HOSTNAME" --ip-address "IP" --memory 16 --vcpu 8 --os "OS"
```

## Contribution

To contribute to the project:

1. Fork the repository
2. Create a branch for your feature
3. Add your modifications
4. Test with provided examples
5. Submit a pull request

## Support

For any questions or issues:

1. Check the documentation in this README
2. Check examples in `linux/example-usage.sh`
3. Use verbose mode (`-v`) for debugging
4. Check configuration with `./linux/config.sh --check`
5. Use installation script to diagnose issues: `./linux/install.sh --test`
6. For Python tools, check `tools/README.md`
