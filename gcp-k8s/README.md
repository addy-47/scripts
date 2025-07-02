# gcloud-kubectl-switch

A powerful shell script to streamline switching between multiple Google Cloud Platform (GCP) projects and their associated Kubernetes clusters.

This script is designed for DevOps engineers, SREs, and developers who frequently work in multi-project/multi-cluster environments. It automates `gcloud` configuration switching, `kubectl` context updates, and authentication, all through simple, memorable aliases.

## Features

-   **One-Command Switching:** Use simple aliases like `switch-my-project` to handle all configuration changes.
-   **Centralized, Secure Configuration:** Manages all project settings in a single `.conf` file, which is kept out of version control.
-   **Automatic Setup:** Creates `gcloud` configurations on the fly for new projects.
-   **Authentication Helper:** Prompts for `gcloud auth login` if the required account is not yet authenticated.
-   **Kubernetes Integration:** Fetches GKE cluster credentials and intelligently renames `kubectl` contexts to your preferred short names using `kubectx`.
-   **Namespace Awareness:** Automatically switches to a predefined Kubernetes namespace using `kubens` after a successful context switch.
-   **Extensible:** Easily add post-switch commands to list VMs, Cloud Storage buckets, or other GCP resources.

## Prerequisites

Ensure the following command-line tools are installed and available in your `PATH`:

-   `gcloud`: The Google Cloud SDK
-   `kubectl`: The Kubernetes command-line tool
-   `kubectx` / `kubens`: For fast `kubectl` context and namespace switching.

## Setup

1.  **Clone or Download:** Place `gcloud-kubectl-switch.sh` in a convenient directory, for example, `~/scripts/gcp-k8s/`.

2.  **Make it Executable:**
    ```bash
    chmod +x ~/scripts/gcp-k8s/gcloud-kubectl-switch.sh
    ```

3.  **Create Configuration File:** In the same directory as the script, create a configuration file named `gcloud-kubectl-switch.conf`.

4.  **Add Configurations:** Populate `gcloud-kubectl-switch.conf` with your project details. See the format below.

5.  **Secure Your Config:** **This is a critical step.** Add your configuration file to your `.gitignore` to prevent committing secrets to version control.
    ```
    # .gitignore
    gcloud-kubectl-switch.conf
    ```

6.  **Source in Your Shell:** Add the script to your shell's startup file (`~/.bashrc`, `~/.zshrc`, etc.).
    ```bash
    # Add this line to the end of your ~/.bashrc or ~/.zshrc
    source ~/scripts/gcp-k8s/gcloud-kubectl-switch.sh
    ```

7.  **Reload Your Shell:** Open a new terminal or run `source ~/.bashrc` to activate the script and its aliases.

## Configuration

Your `gcloud-kubectl-switch.conf` file contains an associative array named `CONFIGS`. Each entry defines a switchable environment.

**Format:**

```shell
# gcloud-kubectl-switch.conf
CONFIGS=(
  ["<alias-name>"]="<project-id>|<gcp-account>|<real-gke-cluster-name>|<gke-region>|<desired-kube-context-name>|<desired-namespace>"
)
```

**Example:**

```shell
#!/bin/bash
CONFIGS=(
  ["prod-main"]="my-prod-project|user@company.com|gke-prod-us-central1-main-app|us-central1|prod"
  ["dev-test"]="my-dev-project|user@company.com|gke-dev-us-east1-testing|us-east1|dev"
)
```

## Usage

Once set up, simply use the aliases you defined in your configuration file.

```bash
# Switch to the 'prod-main' environment
switch-prod-main

# Switch to the 'dev-test' environment
switch-dev-test
```

A new alias will be available immediately after you add a new entry and reload your shell.

## Troubleshooting

-   **Permission Errors:** If `get-credentials` fails, you may need `roles/container.clusterAdmin`. Grant it with:
    ```bash
    gcloud projects add-iam-policy-binding <project-id> \
      --member=user:<account> --role=roles/container.clusterAdmin
    ```
-   **Timeouts/Connectivity:** For private clusters, ensure you are on the correct VPN or network. You can test basic connectivity with `curl -k https://<cluster-ip>`.
-   **Alias Not Found:** Ensure you have reloaded your shell (`source ~/.bashrc`) after adding a new configuration.

---
*Created by Adhbhut Gupta, optimized for DevOps efficiency.*