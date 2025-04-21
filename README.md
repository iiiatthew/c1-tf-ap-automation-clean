# ConductorOne Access Profile Automation via Terraform

This Terraform project automates the creation, configuration, and management of ConductorOne Access Profiles based on mappings defined in a CSV file. It's designed to synchronize access profiles (representing resources from a primary application) with their associated target application entitlements.

This solution utilizes the ConductorOne Terraform provider and supplements it with direct API calls via the HTTP provider for functionality not yet natively supported (like configuring Access Profile Bundle Automation).

## Features

-   **CSV-Driven Configuration:** Define the desired state of access profiles and their entitlements in a simple `maps.csv` file.
-   **Automated Profile Management:** Creates, updates, and deletes ConductorOne Access Profiles based on the CSV content.
-   **Automated Entitlement Assignment:** Configures the specific entitlements that should be requestable within each Access Profile.
-   **Policy Attachment:** Automatically attaches a specified Grant Policy to managed Access Profiles.
-   **Bundle Automation Configuration:** Uses HTTP calls to configure Access Profile Bundle Automation, linking profiles to enrollment entitlements.
-   **GitHub Actions Integration:** Includes a workflow (`.github/workflows/sync.yml`) for automated synchronization on a schedule or manual trigger.

## Prerequisites

-   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (v1.0 or later recommended)
-   A [ConductorOne](https://www.conductorone.com/) instance.
-   ConductorOne API Client ID and Secret with appropriate permissions.
-   IDs for the relevant ConductorOne Applications (primary and target).
-   ID for the ConductorOne Grant Policy to be attached to profiles.
-   A GitHub repository to host the code and run Actions.
-   (Optional but Recommended) [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) account or another remote state backend (e.g., AWS S3).

## Project Structure

```plaintext
.
├── .github/
│   └── workflows/
│       └── sync.yml      # GitHub Actions workflow for automation
├── terraform/
│   ├── data/
│   │   └── maps.csv   # Source of truth for profile mappings
│   ├── variables.tf      # Input variable definitions
│   ├── providers.tf      # Terraform and provider configurations
│   ├── data_sources.tf   # Data sources (CSV file, HTTP API calls)
│   ├── locals.tf         # Data transformation and mapping logic
│   ├── profiles.tf       # Core Access Profile resources
│   ├── automation.tf     # Bundle Automation via null_resource/HTTP
│   └── backend.tf        # (Recommended) Remote state backend config
├── scripts/
│   └── validate_csv.py   # (Optional) Script to validate CSV format
├── .env.example          # Example environment variables file
├── .gitignore            # Git ignore file
├── deployment_and_testing_guide.md # Detailed setup guide
└── README.md             # This file
```

## Configuration

1.  **Mapping File:** Populate `data/maps.csv` with your desired mappings. It **must** include the appropriate headers as defined in your implementation. See the [Deployment Guide](./deployment_and_testing_guide.md) for details.
2.  **Variables:** Terraform requires several variables (like API keys and application IDs). Provide these using one of the following methods:
    *   **Environment Variables (Recommended for CI/CD):** Create a `.env` file (and add it to `.gitignore`) or set environment variables directly, prefixed with `TF_VAR_`. See `.env.example`.
        ```bash
        export TF_VAR_c1_server_url="https://YOUR_INSTANCE.conductorone.com"
        export TF_VAR_c1_client_id="YOUR_C1_CLIENT_ID"
        export TF_VAR_c1_client_secret="YOUR_C1_CLIENT_SECRET"
        export TF_VAR_primary_app_id="YOUR_PRIMARY_APP_ID"
        export TF_VAR_target_app_id="YOUR_TARGET_APP_ID"
        export TF_VAR_ap_request_policy_id="YOUR_POLICY_ID"
        # ... other optional overrides ...
        ```
    *   **Terraform Cloud Variables:** If using Terraform Cloud, configure variables in the workspace settings.

## Usage

### Local Testing

1.  **Navigate to Terraform Directory:**
    ```bash
    cd terraform
    ```
2.  **Initialize Terraform:** Downloads providers and configures the backend.
    ```bash
    terraform init
    ```
3.  **Plan Changes:** Preview the actions Terraform will take. Ensure you have set your variables.
    ```bash
    terraform plan -out=tfplan
    ```
4.  **Apply Changes:** Create or update resources in ConductorOne.
    ```bash
    terraform apply tfplan
    ```

### Automation with GitHub Actions

The included `.github/workflows/sync.yml` workflow automates the `plan` and `apply` steps.

1.  **Configure Secrets:** Add the required `TF_VAR_` values (without the prefix) as secrets in your GitHub repository settings (e.g., `C1_CLIENT_ID`, `PRIMARY_APP_ID`). See the [Deployment Guide](./deployment_and_testing_guide.md) for the full list.
2.  **Configure State:** Ensure the workflow can access the Terraform state (ideally via a remote backend like Terraform Cloud or S3). See the guide for backend setup details.
3.  **Run Workflow:** Trigger the workflow manually via the Actions tab or let it run on its schedule (`cron`).

## State Management

Terraform requires state to track managed resources.

-   **Local State (Default):** Not recommended for automation or collaboration due to risks of data loss and concurrency issues.
-   **Remote State (Recommended):** Use a backend like [Terraform Cloud](https://cloud.hashicorp.com/products/terraform), AWS S3, Azure Storage, etc. Configure this in `terraform/providers.tf`. See the [Deployment Guide](./deployment_and_testing_guide.md) for detailed setup instructions, including Terraform Cloud.

## Detailed Setup and Testing

For comprehensive step-by-step instructions on configuration, local testing, setting up GitHub Actions, configuring remote state (including Terraform Cloud), and troubleshooting, please refer to the [**Deployment and Testing Guide**](./deployment_and_testing_guide.md).
