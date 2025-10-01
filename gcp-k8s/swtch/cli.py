import click
import os
import yaml
from . import switch

CONFIG_FILE_NAME = 'swtch.yaml'

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
    with open(config_file, 'r') as f:
        return yaml.safe_load(f)

@click.group()
@click.version_option(version='0.1.0')
def main():
    """A CLI tool to switch between gcloud and kubectl configurations."""
    pass

@main.command()
def init():
    """Creates a sample swtch.yaml configuration file."""
    if os.path.exists(CONFIG_FILE_NAME):
        click.echo("swtch.yaml already exists.")
        return
    
    sample_config = {
        'configs': {
            'dev': {
                'gcloud': 'gcloud-dev-config',
                'kubectl': 'kubectl-dev-context'
            },
            'prod': {
                'gcloud': 'gcloud-prod-config',
                'kubectl': 'kubectl-prod-context'
            }
        }
    }

    with open(CONFIG_FILE_NAME, 'w') as f:
        yaml.dump(sample_config, f, default_flow_style=False)
    
    click.echo(f"Created sample {CONFIG_FILE_NAME}")
    click.echo("Please place this file in your home directory or the directory where you run swtch.")


@main.command()
@click.option('--show', is_flag=True, help='Show all configurations.')
def list(show):
    """Lists all available configurations."""
    config = get_config()
    if not config:
        click.echo("Configuration file not found. Please run 'swtch init'.")
        return
        
    click.echo("Available configurations:")
    for alias in config.get('configs', {}):
        click.echo(f"- {alias}")

@main.command(context_settings=dict(
    ignore_unknown_options=True,
))
@click.argument('alias', required=False)
@click.option('--show', is_flag=True, help='Show all configurations.')
def switcher(alias, show):
    """Switch to a specified configuration alias."""
    if show:
        list()
        return

    if not alias:
        click.echo("Please specify an alias to switch to.")
        return

    config = get_config()
    if not config:
        click.echo("Configuration file not found. Please run 'swtch init'.")
        return

    if alias not in config.get('configs', {}):
        click.echo(f"Alias '{alias}' not found in configuration.")
        return
    
    switch.switch_config(alias, config['configs'][alias])

if __name__ == '__main__':
    main()