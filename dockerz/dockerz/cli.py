import click
import sys
import os
from .builder import build_and_push_images

def print_welcome_message():
    """Print a welcome message with usage instructions."""
    click.echo(click.style("\nš Welcome to Dockerz!", fg="green", bold=True))
    click.echo("You can run Dockerz in two ways:")
    click.echo("1. Using the command directly:    dockerz [commands]")
    click.echo("2. Using Python module:           py -m dockerz [commands]")
    click.echo("\nCommands:")
    click.echo("  init     Create a sample services.yaml configuration")
    click.echo("  build    Build Docker images based on services.yaml")
    click.echo("\nFor help, run: dockerz --help")
    click.echo()

SAMPLE_CONFIG = """# Base directory to scan for Dockerfiles (relative to project root)
services_dir: ./services

# Google Cloud Configuration
project_id: my-gcp-project
gar_name: my-artifact-registry
region: us-central1

# Build Configuration
global_tag: v1.0.0          # Optional: A global tag applied to all services
max_processes: 4            # Optional: Max parallel builds
use_gar: true              # Optional: Use Google Artifact Registry naming
push_to_gar: true          # Optional: Push to GAR after building

# Optional: Explicitly list services to build
services:
  - name: services/service-a
    image_name: service-a-image  # Optional: Custom image name
    tag: v1.0.1             # Optional: Service-specific tag
  - name: services/service-b
  - name: subdir/service-c
"""

def create_sample_config():
    """Create a sample services.yaml file in the current directory."""
    if os.path.exists('services.yaml'):
        if not click.confirm('services.yaml already exists. Do you want to overwrite it?'):
            return False
    with open('services.yaml', 'w') as f:
        f.write(SAMPLE_CONFIG)
    click.echo(click.style("✓ Created sample services.yaml", fg="green"))
    return True

@click.group()
def cli():
    """Dockerz - Build and push multiple Docker images in parallel."""
    pass

@cli.command()
def init():
    """Initialize a new project with sample configuration."""
    create_sample_config()
    click.echo("\nNext steps:")
    click.echo("1. Edit services.yaml to configure your services")
    click.echo("2. Run 'dockerz build' to build your images")

@cli.command()
@click.option('--config', default='services.yaml', help='Path to services.yaml configuration file.')
@click.option('--max-processes', type=int, help='Maximum number of parallel builds.')
def build(config, max_processes):
    """Build Docker images based on services.yaml configuration."""
    build_and_push_images(config, max_processes)

def main():
    """Main entry point."""
    try:
        if len(sys.argv) == 1:  # No arguments provided
            print_welcome_message()
            return
        cli()
    except Exception as e:
        click.echo(click.style(f"Error: {str(e)}", fg="red"), err=True)
        sys.exit(1)

if __name__ == "__main__":
    main()
