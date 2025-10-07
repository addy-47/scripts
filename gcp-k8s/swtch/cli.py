import click
import os
import re
from . import switch

CONFIG_FILE_NAME = 'gcloud-kubectl-switch.conf'

def find_config_file():
    # Search for config file in current directory, then home directory
    if os.path.exists(CONFIG_FILE_NAME):
        return CONFIG_FILE_NAME
    home_path = os.path.expanduser(f"~/{CONFIG_FILE_NAME}")
    if os.path.exists(home_path):
        return home_path
    return None

def get_config():
    config_file = find_config_file()
    if not config_file:
        return None
    configs = {}
    with open(config_file, 'r') as f:
        content = f.read()
    # Parse the CONFIGS array
    matches = re.findall(r'\["([^"]+)"\]="([^"]*)"', content)
    for key, value in matches:
        configs[key] = value.split('|')
    return configs

@click.group()
@click.version_option(version='0.1.0')
def main():
    """A CLI tool to switch between gcloud and kubectl configurations."""
    pass

@main.command()
def init():
    """Creates a sample gcloud-kubectl-switch.conf configuration file."""
    if os.path.exists(CONFIG_FILE_NAME):
        click.echo(f"{CONFIG_FILE_NAME} already exists.")
        return

    sample_config = '''#!/bin/bash

# Configuration file for gcloud-kubectl-switch.sh
# Format for each entry:
# ["alias-name"]="project-id|account-email|cluster-name|region|context-alias|namespace"
#
# Example entry breakdown:
# - alias-name: Short name you'll use to switch contexts (e.g., "dev", "prod", "staging")
# - project-id: Your GCP project ID
# - account-email: Your GCP account email
# - cluster-name: Name of your GKE cluster
# - region: GCP region where your cluster is located
# - context-alias: Short name for kubectl context (optional, defaults to alias-name)
# - namespace: Default namespace to switch to (optional)

declare -A CONFIGS=(
    # Development environment example
    ["dev"]="my-dev-project|dev@company.com|dev-cluster|us-central1|dev-ctx|default"

    # Production environment example
    ["prod"]="my-prod-project|prod@company.com|prod-cluster|us-east1|prod-ctx|prod"

    # Staging environment example
    ["staging"]="my-staging-project|staging@company.com|staging-cluster|us-west1|staging-ctx|staging"
)

# Add your configurations above. Remove the examples and add your real configurations.
# Remember to keep this file private as it contains sensitive information.
'''

    with open(CONFIG_FILE_NAME, 'w') as f:
        f.write(sample_config)

    click.echo(f"Created sample {CONFIG_FILE_NAME}")
    click.echo("Please edit it with your configurations and place it in your home directory or the directory where you run swtch.")


@main.command()
@click.option('--show', is_flag=True, help='Show all configurations.')
def list(show):
    """Lists all available configurations."""
    config = get_config()
    if not config:
        click.echo("Configuration file not found. Please run 'swtch init'.")
        return

    if not config:
        click.echo("No configurations found in the configuration file.")
        click.echo("Please add configurations to use the script.")
        return

    click.echo("Available configurations from configuration file:")
    click.echo()

    # Find the longest alias name for formatting
    max_alias_len = max(len(alias) for alias in config.keys()) if config else 0
    max_alias_len = max(max_alias_len, len("ALIAS")) + 2

    # Print header
    click.echo(f"{'ALIAS':<{max_alias_len}} PROJECT ID")
    click.echo("-" * (max_alias_len + len("PROJECT ID") + 1))

    for alias in sorted(config.keys()):
        project_id = config[alias][0] if len(config[alias]) > 0 else ""
        click.echo(f"{alias:<{max_alias_len}} {project_id}")

    click.echo()
    if config:
        first_alias = sorted(config.keys())[0]
        click.echo(f"To switch, use: swtch switch {first_alias}")

@main.command()
@click.argument('alias', required=False)
@click.option('--show', is_flag=True, help='Show all configurations.')
def switch(alias, show):
    """Switch to a specified configuration alias."""
    if show:
        list()
        return

    if not alias:
        click.echo("Usage: swtch switch <alias-name>")
        click.echo("To see available aliases, run: swtch list")
        click.echo()
        list()
        return

    config = get_config()
    if not config:
        click.echo("Configuration file not found. Please run 'swtch init'.")
        return

    if alias not in config:
        click.echo(f"Error: Configuration '{alias}' not found.")
        click.echo(f"Available configurations: {', '.join(config.keys())}")
        click.echo("Edit the CONFIGS array in the configuration file to add new configurations.")
        return

    switch.switch_config(alias, config[alias])

if __name__ == '__main__':
    main()