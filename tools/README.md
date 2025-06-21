# Python Tools for SnipeIT

This directory contains Python tools to interact with SnipeIT.

## Available Scripts

### `list-settings.py` - SnipeIT Configuration Analyzer

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
./install-python-deps.sh --all
```

**Manual installation:**
```bash
pip3 install requests rich
```

#### Usage

```bash
python3 list-settings.py [OPTIONS]
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
python3 list-settings.py -s "https://snipeit.company.com" -t "your-api-token"
```

**List models and custom fields:**
```bash
python3 list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --models --custom-fields
```

**Export configuration:**
```bash
python3 list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --export --export-file "config.json"
```

**Display all information:**
```bash
python3 list-settings.py -s "https://snipeit.company.com" -t "your-api-token" --all
```

### `install-python-deps.sh` - Installation Script

Bash script to automate Python dependencies installation.

#### Features

- ✅ Python 3 verification
- ✅ pip verification
- ✅ Automatic dependency installation
- ✅ Installation testing
- ✅ Support for different operating systems

#### Usage

```bash
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

### `requirements.txt` - Python Dependencies

File listing required Python dependencies:

- `requests>=2.28.0` : For HTTP calls to SnipeIT API
- `rich>=12.0.0` : For colored display and tables

## Python Script Architecture

The `list-settings.py` script is organized in classes:

### `SnipeITClient`
- HTTP connection management
- Bearer Token authentication
- API calls with error handling

### `SnipeITSettingsLister`
- Information display with Rich
- Colored and organized tables
- Data export
- Different data types management

## Detailed Features

### Connection Test
- Server accessibility verification
- API token validation
- Display with spinner and colors

### Configuration List
- **Categories** : Asset types (hardware, software, etc.)
- **Models** : Asset models with manufacturers
- **Custom Fields** : Fields configured in SnipeIT
- **Status Labels** : Available statuses (Ready to Deploy, Deployed, etc.)
- **Companies** : Configured organizations
- **Locations** : Physical locations
- **Departments** : Organizational units
- **Suppliers** : Vendors and service providers
- **Manufacturers** : Equipment manufacturers

### JSON Export
- Complete configuration backup
- Structured and readable format
- Usable for analysis or migration

## User Interface

The script uses the Rich library for professional display:

- **Colors** : Visual differentiation of information types
- **Tables** : Data organized in columns
- **Panels** : Important information framed
- **Progress** : Progress indicators
- **Syntax highlighting** : JSON export coloring

## Error Handling

- Input parameter validation
- Connection error handling
- Explicit error messages
- Appropriate exit codes

## Output Examples

### Connection Test
```
┌─ SnipeIT Configuration ──────────────────────────────────────────────┐
│ Server: https://snipeit.company.com                                 │
│ Token: your-api-t...                                                 │
└──────────────────────────────────────────────────────────────────────┘

✅ Successfully connected to SnipeIT server!
```

### Models List
```
🔧 Models

┌─ Asset Models ──────────────────────────────────────────────────────┐
│ ID │ Name              │ Category │ Manufacturer │ Asset Count     │
├─────┼──────────────────┼──────────┼──────────────┼─────────────────┤
│ 1  │ Dell OptiPlex     │ Desktop  │ Dell         │ 25              │
│ 2  │ HP ProBook 450    │ Laptop   │ HP           │ 12              │
└─────┴──────────────────┴──────────┴──────────────┴─────────────────┘
```

## Integration with Bash Scripts

The Python script can be used in complement with bash scripts:

1. **Analysis** : Use `list-settings.py` to analyze configuration
2. **Creation** : Use `snipeit-agent.sh` to create assets
3. **Verification** : Re-use `list-settings.py` to verify creations

## Development

### Adding New Features

1. **New endpoints** : Add in `SnipeITClient.get_api_data()`
2. **New lists** : Create a method in `SnipeITSettingsLister`
3. **New export formats** : Extend the `export_config()` method

### Tests

```bash
# Help test
python3 list-settings.py -h

# Test with fake server (to test error handling)
python3 list-settings.py -s "https://invalid-server.com" -t "invalid-token"
```

## Support

For any questions or issues:

1. Check prerequisites: `./install-python-deps.sh --test`
2. Test connection: `python3 list-settings.py -s URL -t TOKEN`
3. Check help: `python3 list-settings.py -h`
4. Check error logs for more details 