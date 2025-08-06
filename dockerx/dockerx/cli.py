import click
from .builder import build_and_push_images

@click.command()
@click.option('--config', default='services.yaml', help='Path to services.yaml configuration file.')
@click.option('--max-processes', type=int, help='Maximum number of parallel builds.')
def main(config, max_processes):
    """Build and optionally push multiple Docker images in parallel."""
    build_and_push_images(config, max_processes)

if __name__ == "__main__":
    main()