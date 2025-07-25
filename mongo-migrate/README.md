# MongoDB Migration Tool

A simple and modular tool to automate MongoDB data migrations between Virtual Machines (VMs) and Kubernetes StatefulSets.

This tool provides a single, unified CLI command (`mongo-migrate`) to handle various migration scenarios, including:

*   **VM to VM**
*   **VM to Kubernetes StatefulSet**
*   **Kubernetes StatefulSet to StatefulSet**

It's designed to be safe, with features like backup verification, retry logic, and detailed post-migration checks.

## Prerequisites

Before you begin, ensure you have the following:

*   **Operating System:** Linux or macOS with Bash.
*   **Tools:**
    *   `mongosh`, `mongodump`, `mongorestore`
    *   `kubectl`, `kubectx` (for Kubernetes migrations)
    *   `ssh`, `scp` (for VM migrations)
*   **Passwordless SSH Access:** For VM-based migrations, configure passwordless SSH access to the source and target machines.
    ```bash
    ssh-copy-id <user>@<vm-ip>
    ```
*   **Kubernetes Access:** For Kubernetes-based migrations, ensure your `~/.kube/config` is configured with access to the source and target clusters.
*   **Sufficient Disk Space:** Make sure you have enough free space in your backup directory (default: `/tmp/mongo-backup`).

## Quick Install & Setup

1.  **Clone or Download the Scripts:**
    Make sure you have all the files from the `mongo-migrate` directory.

2.  **Make Scripts Executable:**
    ```bash
    chmod +x mongo-migrate.sh migrations/*.sh
    ```

3.  **Configure Your Environment:**
    *   Copy the sample configuration file:
        ```bash
        cp mongo-migrate-sample.conf ~/.mongo-migrate.conf
        ```
    *   Edit `~/.mongo-migrate.conf` with your environment details (MongoDB URIs, SSH credentials, Kubernetes contexts, etc.).
        ```bash
        nano ~/.mongo-migrate.conf
        ```
    *   Secure the configuration file:
        ```bash
        chmod 600 ~/.mongo-migrate.conf
        ```

4.  **(Optional) Create a Global Alias:**
    For easier access, add an alias to your shell's configuration file (e.g., `~/.bashrc`, `~/.zshrc`).
    ```bash
    echo "alias mongo-migrate='~/path/to/your/scripts/mongo-migrate/mongo-migrate.sh'" >> ~/.bashrc
    source ~/.bashrc
    ```
    *Replace `~/path/to/your/scripts/` with the actual path to the project.*

## Usage

Once configured, you can run migrations using the `mongo-migrate` command.

**Standard Usage (using default `~/.mongo-migrate.conf`):**

```bash
# VM to VM Migration
mongo-migrate vm-vm

# VM to Kubernetes StatefulSet Migration
mongo-migrate vm-ss

# Kubernetes StatefulSet to StatefulSet Migration
mongo-migrate ss-ss
```

**Using a Custom Configuration File:**

If you need to use different settings for a specific migration, you can provide a path to a custom configuration file.

```bash
mongo-migrate vm-ss /path/to/your/custom-config.conf
```

**Checking Logs:**

A detailed log file named `migration.log` is created in the directory where you run the command. You can check this file for progress and troubleshooting.

```bash
tail -f migration.log
```

## Configuration Details

The `mongo-migrate.conf` file holds all the necessary parameters for the different migration types.

**For enhanced security, consider using a secrets management tool like HashiCorp Vault or AWS Secrets Manager to store your MongoDB credentials instead of leaving them in the configuration file.**

| Variable                  | Description                                                              |
| ------------------------- | ------------------------------------------------------------------------ |
| `SOURCE_MONGO_URI`        | Connection string for the source MongoDB.                                |
| `TARGET_MONGO_URI`        | Connection string for the target MongoDB.                                |
| `BACKUP_DIR`              | Directory to store the temporary backup.                                 |
| `SOURCE_VM_IP`            | IP address of the source VM.                                             |
| `SOURCE_VM_USER`          | SSH user for the source VM.                                              |
| `TARGET_VM_IP`            | IP address of the target VM.                                             |
| `TARGET_VM_USER`          | SSH user for the target VM.                                              |
| `TARGET_DOCKER_CONTAINER` | Name of the Docker container running MongoDB on the target VM.           |
| `SOURCE_K8S_CONTEXT`      | `kubectl` context for the source Kubernetes cluster.                     |
| `SOURCE_K8S_NAMESPACE`    | Namespace of the source pod in Kubernetes.                               |
| `SOURCE_K8S_POD`          | Name of the source MongoDB pod in Kubernetes.                            |
| `TARGET_K8S_CONTEXT`      | `kubectl` context for the target Kubernetes cluster.                     |
| `TARGET_K8S_NAMESPACE`    | Namespace of the target pod in Kubernetes.                               |
| `TARGET_K8S_POD`          | Name of the target MongoDB pod in Kubernetes.                            |

## Extending the Tool

The tool is designed to be modular. To add a new migration type (e.g., `aws-to-gcp`):

1.  **Create a new script** in the `migrations/` directory (e.g., `aws-to-gcp.sh`).
2.  **Implement the migration logic** within the new script. You can use the existing configuration variables or add new ones to `mongo-migrate.conf`.
3.  **Update the `mongo-migrate.sh` script** to recognize the new migration type in the main `case` statement.

## Troubleshooting

*   **SSH Errors:** Verify your SSH keys are set up correctly and that there is network connectivity between the machines.
*   **Kubernetes Errors:** Check your `~/.kube/config` file and ensure you can connect to the clusters using `kubectl`.
*   **MongoDB Errors:** Double-check your MongoDB connection URIs, including usernames, passwords, and ports.
*   **Disk Space Issues:** Ensure the `BACKUP_DIR` has enough free space.
*   **Check the Logs:** The `migration.log` file is your best friend for debugging. It contains detailed error messages.