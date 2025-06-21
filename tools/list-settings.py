#!/usr/bin/env python3
"""
Script to test connection to SnipeIT server and list configurations
Displays asset types, custom fields, models, etc.
"""

import argparse
import json
import sys
from typing import Dict, List, Optional, Any
from urllib.parse import urljoin, urlparse
import requests
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.text import Text
from rich import print as rprint
from rich.syntax import Syntax

# Color and style configuration
console = Console()

class SnipeITClient:
    """Client to interact with SnipeIT API"""
    
    def __init__(self, server_url: str, api_token: str):
        self.server_url = server_url.rstrip('/')
        self.api_token = api_token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_token}',
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        })
    
    def test_connection(self) -> bool:
        """Test connection to SnipeIT server"""
        try:
            response = self.session.get(f"{self.server_url}/api/v1/statuslabels")
            if response.status_code == 200:
                return True
            else:
                console.print(f"[red]Connection error: {response.status_code}[/red]")
                return False
        except requests.exceptions.RequestException as e:
            console.print(f"[red]Connection error: {e}[/red]")
            return False
    
    def get_api_data(self, endpoint: str) -> Optional[Dict]:
        """Get data from an API endpoint"""
        try:
            url = f"{self.server_url}/api/v1/{endpoint}"
            response = self.session.get(url)
            
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 404:
                console.print(f"[yellow]Endpoint {endpoint} not found (404) - may not be available in this SnipeIT version[/yellow]")
                return None
            elif response.status_code == 401:
                console.print(f"[red]Authentication error (401) for {endpoint} - check your API token[/red]")
                return None
            elif response.status_code == 403:
                console.print(f"[red]Access denied (403) for {endpoint} - check your token permissions[/red]")
                return None
            else:
                console.print(f"[red]API error {endpoint}: {response.status_code}[/red]")
                return None
        except requests.exceptions.RequestException as e:
            console.print(f"[red]Request error {endpoint}: {e}[/red]")
            return None

class SnipeITSettingsLister:
    """Class to list SnipeIT configurations"""
    
    def __init__(self, client: SnipeITClient):
        self.client = client
    
    def display_server_info(self):
        """Display server information"""
        panel = Panel(
            f"[bold blue]Server:[/bold blue] {self.client.server_url}\n"
            f"[bold blue]Token:[/bold blue] {self.client.api_token[:10]}...",
            title="[bold green]SnipeIT Configuration[/bold green]",
            border_style="blue"
        )
        console.print(panel)
    
    def test_connection(self) -> bool:
        """Test connection and display result"""
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console
        ) as progress:
            task = progress.add_task("Testing connection...", total=None)
            
            if self.client.test_connection():
                progress.update(task, description="✅ Connection successful")
                console.print("[green]Successfully connected to SnipeIT server![/green]")
                return True
            else:
                progress.update(task, description="❌ Connection failed")
                console.print("[red]Unable to connect to SnipeIT server[/red]")
                return False
    
    def list_asset_types(self):
        """List available asset types"""
        console.print("\n[bold cyan]📋 Asset Types[/bold cyan]")
        
        data = self.client.get_api_data("categories")
        if not data:
            console.print("[red]Unable to retrieve categories[/red]")
            return
        
        table = Table(title="Asset Categories")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Type", style="yellow")
        table.add_column("Asset Count", style="magenta")
        
        for category in data.get('rows', []):
            table.add_row(
                str(category.get('id', '')),
                category.get('name', ''),
                category.get('category_type', ''),
                str(category.get('assets_count', 0))
            )
        
        console.print(table)
    
    def list_models(self):
        """List available models"""
        console.print("\n[bold cyan]🔧 Models[/bold cyan]")
        
        data = self.client.get_api_data("models")
        if not data:
            console.print("[red]Unable to retrieve models[/red]")
            return
        
        table = Table(title="Asset Models")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Category", style="yellow")
        table.add_column("Manufacturer", style="blue")
        table.add_column("Asset Count", style="magenta")
        
        for model in data.get('rows', [])[:20]:  # Limit to 20 for display
            table.add_row(
                str(model.get('id', '')),
                model.get('name', ''),
                model.get('category', {}).get('name', ''),
                model.get('manufacturer', {}).get('name', ''),
                str(model.get('assets_count', 0))
            )
        
        if len(data.get('rows', [])) > 20:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 20} other models[/yellow]")
        
        console.print(table)
    
    def list_custom_fields(self):
        """List custom fields"""
        console.print("\n[bold cyan]🏷️ Custom Fields[/bold cyan]")
        
        data = self.client.get_api_data("fields")
        if not data:
            console.print("[yellow]No custom fields found or endpoint not available[/yellow]")
            console.print("[yellow]Note: Custom fields may not be enabled in your SnipeIT instance[/yellow]")
            return
        
        table = Table(title="Custom Fields")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Type", style="yellow")
        table.add_column("Format", style="blue")
        table.add_column("Required", style="magenta")
        table.add_column("Elements", style="white")
        
        for field in data.get('rows', []):
            required = "✅" if field.get('required', False) else "❌"
            
            # Safe handling of elements that can be None
            elements = field.get('field_values_array', [])
            if elements is None:
                elements = []
            elements_str = ", ".join(elements[:3]) + ("..." if len(elements) > 3 else "")
            
            table.add_row(
                str(field.get('id', '')),
                field.get('name', ''),
                field.get('format', ''),
                field.get('field_type', ''),
                required,
                elements_str
            )
        
        console.print(table)
    
    def list_status_labels(self):
        """List status labels"""
        console.print("\n[bold cyan]🏷️ Status Labels[/bold cyan]")
        
        data = self.client.get_api_data("statuslabels")
        if not data:
            console.print("[red]Unable to retrieve status labels[/red]")
            return
        
        table = Table(title="Status Labels")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Type", style="yellow")
        table.add_column("Color", style="blue")
        table.add_column("Pivot", style="magenta")
        
        for status in data.get('rows', []):
            color = status.get('color', '')
            color_display = f"[{color}]{color}[/{color}]" if color else ""
            
            table.add_row(
                str(status.get('id', '')),
                status.get('name', ''),
                status.get('type', ''),
                color_display,
                str(status.get('pivot', {}).get('assets_count', 0))
            )
        
        console.print(table)
    
    def list_companies(self):
        """List companies"""
        console.print("\n[bold cyan]🏢 Companies[/bold cyan]")
        
        data = self.client.get_api_data("companies")
        if not data:
            console.print("[red]Unable to retrieve companies[/red]")
            return
        
        table = Table(title="Companies")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Assets", style="yellow")
        table.add_column("Licenses", style="blue")
        table.add_column("Accessories", style="magenta")
        
        for company in data.get('rows', [])[:15]:  # Limit to 15
            table.add_row(
                str(company.get('id', '')),
                company.get('name', ''),
                str(company.get('assets_count', 0)),
                str(company.get('licenses_count', 0)),
                str(company.get('accessories_count', 0))
            )
        
        if len(data.get('rows', [])) > 15:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 15} other companies[/yellow]")
        
        console.print(table)
    
    def list_locations(self):
        """List locations"""
        console.print("\n[bold cyan]📍 Locations[/bold cyan]")
        
        data = self.client.get_api_data("locations")
        if not data:
            console.print("[red]Unable to retrieve locations[/red]")
            return
        
        table = Table(title="Locations")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Parent", style="yellow")
        table.add_column("Assets", style="blue")
        table.add_column("Address", style="magenta")
        
        for location in data.get('rows', [])[:15]:  # Limit to 15
            parent = location.get('parent', {})
            parent_name = parent.get('name', '') if parent else ''
            
            # Safe handling of address that can be None
            address = location.get('address', '')
            if address is None:
                address = ''
            address_display = address[:30] + "..." if len(address) > 30 else address
            
            table.add_row(
                str(location.get('id', '')),
                location.get('name', ''),
                parent_name,
                str(location.get('assets_count', 0)),
                address_display
            )
        
        if len(data.get('rows', [])) > 15:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 15} other locations[/yellow]")
        
        console.print(table)
    
    def list_departments(self):
        """List departments"""
        console.print("\n[bold cyan]🏢 Departments[/bold cyan]")
        
        data = self.client.get_api_data("departments")
        if not data:
            console.print("[red]Unable to retrieve departments[/red]")
            return
        
        table = Table(title="Departments")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Company", style="yellow")
        table.add_column("Manager", style="blue")
        table.add_column("Users", style="magenta")
        
        for dept in data.get('rows', [])[:15]:  # Limit to 15
            company = dept.get('company', {})
            company_name = company.get('name', '') if company else ''
            manager = dept.get('manager', {})
            manager_name = manager.get('name', '') if manager else ''
            
            table.add_row(
                str(dept.get('id', '')),
                dept.get('name', ''),
                company_name,
                manager_name,
                str(dept.get('users_count', 0))
            )
        
        if len(data.get('rows', [])) > 15:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 15} other departments[/yellow]")
        
        console.print(table)
    
    def list_suppliers(self):
        """List suppliers"""
        console.print("\n[bold cyan]🏪 Suppliers[/bold cyan]")
        
        data = self.client.get_api_data("suppliers")
        if not data:
            console.print("[red]Unable to retrieve suppliers[/red]")
            return
        
        table = Table(title="Suppliers")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("Contact", style="yellow")
        table.add_column("Email", style="blue")
        table.add_column("Phone", style="magenta")
        
        for supplier in data.get('rows', [])[:15]:  # Limit to 15
            table.add_row(
                str(supplier.get('id', '')),
                supplier.get('name', ''),
                supplier.get('contact', ''),
                supplier.get('email', ''),
                supplier.get('phone', '')
            )
        
        if len(data.get('rows', [])) > 15:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 15} other suppliers[/yellow]")
        
        console.print(table)
    
    def list_manufacturers(self):
        """List manufacturers"""
        console.print("\n[bold cyan]🏭 Manufacturers[/bold cyan]")
        
        data = self.client.get_api_data("manufacturers")
        if not data:
            console.print("[red]Unable to retrieve manufacturers[/red]")
            return
        
        table = Table(title="Manufacturers")
        table.add_column("ID", style="cyan", no_wrap=True)
        table.add_column("Name", style="green")
        table.add_column("URL", style="yellow")
        table.add_column("Support Email", style="blue")
        table.add_column("Support Phone", style="magenta")
        
        for manufacturer in data.get('rows', [])[:15]:  # Limit to 15
            # Safe handling of URL that can be None
            url = manufacturer.get('url', '')
            if url is None:
                url = ''
            url_display = url[:30] + "..." if len(url) > 30 else url
            
            table.add_row(
                str(manufacturer.get('id', '')),
                manufacturer.get('name', ''),
                url_display,
                manufacturer.get('support_email', ''),
                manufacturer.get('support_phone', '')
            )
        
        if len(data.get('rows', [])) > 15:
            console.print(f"[yellow]... and {len(data.get('rows', [])) - 15} other manufacturers[/yellow]")
        
        console.print(table)
    
    def show_api_endpoints(self):
        """Display available API endpoints"""
        console.print("\n[bold cyan]🔗 Available API Endpoints[/bold cyan]")
        
        endpoints = [
            ("hardware", "Hardware assets"),
            ("models", "Models"),
            ("categories", "Categories"),
            ("fields", "Custom fields"),
            ("statuslabels", "Status labels"),
            ("companies", "Companies"),
            ("locations", "Locations"),
            ("departments", "Departments"),
            ("suppliers", "Suppliers"),
            ("manufacturers", "Manufacturers"),
            ("users", "Users"),
            ("licenses", "Licenses"),
            ("accessories", "Accessories"),
            ("consumables", "Consumables"),
            ("components", "Components"),
        ]
        
        table = Table(title="SnipeIT API Endpoints")
        table.add_column("Endpoint", style="cyan")
        table.add_column("Description", style="green")
        table.add_column("URL", style="yellow")
        
        for endpoint, description in endpoints:
            url = f"{self.client.server_url}/api/v1/{endpoint}"
            table.add_row(endpoint, description, url)
        
        console.print(table)
    
    def export_config(self, filename: str = "snipeit_config.json"):
        """Export configuration to JSON format"""
        console.print(f"\n[bold cyan]💾 Exporting configuration to {filename}[/bold cyan]")
        
        config = {
            "server_url": self.client.server_url,
            "timestamp": None,  # Will be filled by json.dumps
            "categories": self.client.get_api_data("categories"),
            "models": self.client.get_api_data("models"),
            "fields": self.client.get_api_data("fields"),
            "statuslabels": self.client.get_api_data("statuslabels"),
            "companies": self.client.get_api_data("companies"),
            "locations": self.client.get_api_data("locations"),
            "departments": self.client.get_api_data("departments"),
            "suppliers": self.client.get_api_data("suppliers"),
            "manufacturers": self.client.get_api_data("manufacturers"),
        }
        
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=2, ensure_ascii=False)
            console.print(f"[green]Configuration exported successfully to {filename}[/green]")
        except Exception as e:
            console.print(f"[red]Error during export: {e}[/red]")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Test connection and list SnipeIT configurations",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Usage examples:
  python list-settings.py -s https://snipeit.company.com -t your-token
  python list-settings.py -s https://snipeit.company.com -t your-token --export
  python list-settings.py -s https://snipeit.company.com -t your-token --models --custom-fields
        """
    )
    
    parser.add_argument(
        '-s', '--server',
        required=True,
        help='SnipeIT server URL (ex: https://snipeit.company.com)'
    )
    
    parser.add_argument(
        '-t', '--token',
        required=True,
        help='SnipeIT API token'
    )
    
    parser.add_argument(
        '--all',
        action='store_true',
        help='Display all configurations'
    )
    
    parser.add_argument(
        '--categories',
        action='store_true',
        help='List asset categories'
    )
    
    parser.add_argument(
        '--models',
        action='store_true',
        help='List models'
    )
    
    parser.add_argument(
        '--custom-fields',
        action='store_true',
        help='List custom fields'
    )
    
    parser.add_argument(
        '--status-labels',
        action='store_true',
        help='List status labels'
    )
    
    parser.add_argument(
        '--companies',
        action='store_true',
        help='List companies'
    )
    
    parser.add_argument(
        '--locations',
        action='store_true',
        help='List locations'
    )
    
    parser.add_argument(
        '--departments',
        action='store_true',
        help='List departments'
    )
    
    parser.add_argument(
        '--suppliers',
        action='store_true',
        help='List suppliers'
    )
    
    parser.add_argument(
        '--manufacturers',
        action='store_true',
        help='List manufacturers'
    )
    
    parser.add_argument(
        '--api-endpoints',
        action='store_true',
        help='Display available API endpoints'
    )
    
    parser.add_argument(
        '--export',
        action='store_true',
        help='Export configuration to JSON format'
    )
    
    parser.add_argument(
        '--export-file',
        default='snipeit_config.json',
        help='Export filename (default: snipeit_config.json)'
    )
    
    args = parser.parse_args()
    
    # Validate URL
    if not args.server.startswith(('http://', 'https://')):
        console.print("[red]Server URL must start with http:// or https://[/red]")
        sys.exit(1)
    
    # Create client
    client = SnipeITClient(args.server, args.token)
    lister = SnipeITSettingsLister(client)
    
    # Display server information
    lister.display_server_info()
    
    # Test connection
    if not lister.test_connection():
        sys.exit(1)
    
    # Determine what to display
    show_all = args.all or not any([
        args.categories, args.models, args.custom_fields, args.status_labels,
        args.companies, args.locations, args.departments, args.suppliers,
        args.manufacturers, args.api_endpoints
    ])
    
    # Display configurations
    if show_all or args.categories:
        lister.list_asset_types()
    
    if show_all or args.models:
        lister.list_models()
    
    if show_all or args.custom_fields:
        lister.list_custom_fields()
    
    if show_all or args.status_labels:
        lister.list_status_labels()
    
    if show_all or args.companies:
        lister.list_companies()
    
    if show_all or args.locations:
        lister.list_locations()
    
    if show_all or args.departments:
        lister.list_departments()
    
    if show_all or args.suppliers:
        lister.list_suppliers()
    
    if show_all or args.manufacturers:
        lister.list_manufacturers()
    
    if show_all or args.api_endpoints:
        lister.show_api_endpoints()
    
    # Export if requested
    if args.export:
        lister.export_config(args.export_file)
    
    console.print("\n[bold green]✅ Analysis completed![/bold green]")

if __name__ == "__main__":
    main()
