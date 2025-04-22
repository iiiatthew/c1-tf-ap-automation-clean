# ConductorOne Access Profile Terraform Solution: Deployment and Testing Guide

This guide provides step-by-step instructions for configuring, testing, and deploying the ConductorOne Access Management solution based on Terraform.

---

## Table of Contents

1. [Initial Configuration](#initial-configuration)
2. [Local Testing](#local-testing)
3. [GitHub Actions Configuration](#github-actions-configuration)
4. [Setting Up Remote State](#setting-up-remote-state)
5. [Maintenance & Monitoring](#maintenance--monitoring)
6. [Troubleshooting](#troubleshooting)

---

## Initial Configuration

Before deploying, you need to gather information and set up your mapping file.

### 1. Prepare Mapping CSV

Create or update `data/maps.csv` with appropriate mappings:

- Create a CSV file with headers that match your implementation needs
- Populate with your desired mappings between primary resources and target entitlements
- Use proper formatting: no special characters in keys, required permissions format, no typos

Example CSV file structure (adjust based on your specific primary and target applications):
```csv
source_resource,target_resource,target_entitlement
resource_1,target_resource_1,viewer
resource_2,target_resource_2,admin
resource_3,target_resource_3,contributor
```

### 2. Collect Required IDs

From your ConductorOne instance, gather the following IDs:

1. **Primary Application ID**: The application ID for your primary resource application (from which resources will be mapped to access profiles)
   - Navigate to Applications in C1
   - Copy the ID from the URL when viewing the primary application

2. **Target Application ID**: The application ID for your target entitlement application
   - Navigate to Applications in C1
   - Copy the ID from the URL when viewing the target application

3. **Request Policy ID**: The ID of the request policy to attach to access profiles
   - Navigate to Policies
   - Select your desired request policy
   - Copy the ID from the URL

4. **Update variables.tf**: Update the relevant placeholders in the variables.tf file with your collected IDs 

### 3. Generate API Credentials

Create ConductorOne API credentials:

1. Click your user icon → API Keys
2. Create credential → fill out form
3. Save the Client ID and Client Secret securely


---

## Local Testing

Testing locally helps verify your configuration before deployment.

### 1. Set Environment Variables

Create a `.env` file (don't commit) with your configuration:

```sh
# Required parameters
export TF_VAR_c1_server_url="https://YOUR_INSTANCE.conductorone.com"
export TF_VAR_c1_client_id="YOUR_C1_CLIENT_ID"
export TF_VAR_c1_client_secret="YOUR_C1_CLIENT_SECRET"
export TF_VAR_primary_app_id="YOUR_PRIMARY_APP_ID"
export TF_VAR_target_app_id="YOUR_TARGET_APP_ID"
export TF_VAR_ap_request_policy_id="YOUR_POLICY_ID"
```

Load these variables:
```bash
source .env
```

### 2. Initialize Terraform

Navigate to the terraform directory and initialize:

```bash
cd terraform
terraform init
```

### 3. Test Individual Components

Test data sources and output formats:

```bash
# Test CSV Import
terraform plan -target=data.local_file.mapping_csv

# View Locals (Transformed Data)
terraform console
> local.map_data
> local.ap_settings
> local.ap_entitlements
```

### 4. Run Full Plan

Perform a full plan to preview changes:

```bash
terraform plan -out=tfplan
```

Review the plan carefully:
- Access Profiles to be created/updated/deleted
- Entitlements that will be added/removed
- Bundle automation changes

### 5. Apply Changes

Apply the plan to make changes in ConductorOne:

```bash
terraform apply tfplan
```

Test in the ConductorOne UI:
1. Verify Access Profiles were created correctly
2. Check that entitlements are linked properly
3. Confirm bundle automation is functioning
4. Test requesting access to a profile

### 6. Verify State

Examine the Terraform state:

```bash
terraform state list
terraform state show 'resource.name'
```

---

## GitHub Actions Configuration

For production use, configure GitHub Actions for automated synchronization.

### 1. Create GitHub Secrets

Add the following secrets to your repository:

```
C1_SERVER_URL (e.g., https://YOUR_INSTANCE.conductorone.com)
C1_CLIENT_ID
C1_CLIENT_SECRET
PRIMARY_APP_ID
TARGET_APP_ID
AP_REQUEST_POLICY_ID
```

Additional secrets for remote state (if using, see section below):
```
# For Terraform Cloud
TF_API_TOKEN

# For AWS S3
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### 2. Configure Workflow Schedule

Edit `.github/workflows/sync.yml` to set your desired schedule:

```yaml
on:
  # Uncomment to enable scheduling 
  # schedule:
    # - cron: '0 * * * *'    # Run every hour (60 minutes)
    # - cron: '* * * * *'  # Run every minute (for testing)
```

### 3. Test Workflow

1. Trigger the workflow manually from GitHub Actions tab
2. Check run logs for errors
3. Verify changes in ConductorOne

### 4. Production Readiness Checklist

- [ ] Remote state configured (see next section)
- [ ] Workflow schedule set appropriately
- [ ] CSV validation added (optional but recommended)
- [ ] Error notifications configured (e.g., GitHub team mentions)
- [ ] Documentation updated with project specifics

---

## Setting Up Remote State

For production use, a remote state backend is strongly recommended. Choose one of these methods:

### Option A: Terraform Cloud (Recommended)

1. **Create Terraform Cloud Account and Workspace**:
   - Sign up at [app.terraform.io](https://app.terraform.io)
   - Create a new workspace (choose "CLI-driven workflow")
   - Note the organization and workspace names

2. **Generate API Token**:
   - Create a user or team API token in Terraform Cloud
   - Add as GitHub secret: `TF_API_TOKEN`

3. **Update Backend Configuration**:
   Edit `terraform/backend.tf`:
   ```hcl
   terraform {
     backend "remote" {
       organization = "your-org-name"
       workspaces {
         name = "c1-access-profile-automation"
       }
     }
   }
   ```

4. **Configure Workspace Variables** (Optional):
   - Add sensitive variables in the Terraform Cloud workspace settings
   - Set environment=true for environment variables like `TF_VAR_c1_client_secret`
   - This allows removing these from GitHub secrets if preferred

5. **Update GitHub Workflow**:
   - The workflow already has Terraform Cloud integration
   - Add your backend configuration details

### Option B: AWS S3 Backend

1. **Create S3 Bucket**:
   ```bash
   aws s3 mb s3://your-terraform-state-bucket --region your-region
   ```

2. **Enable Versioning** (Recommended):
   ```bash
   aws s3api put-bucket-versioning --bucket your-terraform-state-bucket --versioning-configuration Status=Enabled
   ```

3. **Create DynamoDB Table for Locking** (Recommended):
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

4. **Update Backend Configuration**:
   Edit `terraform/backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket"
       key            = "c1-access-profiles/terraform.tfstate"
       region         = "your-region"
       dynamodb_table = "terraform-state-lock"
       encrypt        = true
     }
   }
   ```

5. **Add AWS Credentials to GitHub Secrets**:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - Either use restricted IAM role or separate state-only credentials

6. **Update GitHub Workflow**:
   Modify `.github/workflows/sync.yml` to configure AWS credentials:
   ```yaml
   - name: Configure AWS Credentials
     uses: aws-actions/configure-aws-credentials@v1
     with:
       aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
       aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
       aws-region: your-region
   ```

---

## Maintenance & Monitoring

### Updating Mappings

To update resource-to-entitlement mappings:

1. Edit `data/maps.csv`
2. Commit and push changes
3. Trigger the workflow manually or wait for scheduled run

### Monitoring Execution

1. **GitHub Actions Run Logs**: 
   - Check workflow runs in the Actions tab
   - Download plan/apply logs as artifacts

2. **Error Handling**:
   - GitHub Actions will report failures via workflow status
   - Failed runs won't modify the environment (require plan approval)

### Troubleshooting Common Issues

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| 401 Unauthorized | Invalid/expired credentials | Refresh API credentials |
| 403 Forbidden | Insufficient permissions | Update API client permissions |
| No changes detected | CSV format issues | Validate CSV format |
| Rate limiting errors | Too many API calls | Add backoff/retry logic |
| Terraform lock timeout | Concurrent runs | Ensure only one workflow runs at a time |

---

## Troubleshooting

### CSV Validation

The CSV file must have proper formatting:
- Headers must match expected fields in your implementation
- Data must be properly cleaned (no invalid characters)
- Permissions must match valid values for your target application

### Access Issues

If encountering permission errors:
1. Verify API Client has all required permissions in ConductorOne (Full Permissions)
2. Check that application IDs are correct
3. Verify the grant policy still exists and is properly configured

### Terraform Execution Errors

Issues with Terraform runs:
1. Check state integrity with `terraform state list`
2. Look for transient API errors in logs
3. For persistent issues, consider:
   ```bash
   terraform state rm 'problematic.resource'
   ```

### GitHub Actions Workflow Failures

If the GitHub workflow fails:
1. Check logs for specific error messages
2. Verify all secrets are set correctly
3. Test with a local run using the same credentials
4. Check for concurrent runs causing locks

