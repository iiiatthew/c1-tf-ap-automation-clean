# Pagination module for ConductorOne API
# This file contains utilities for fetching paginated data from the C1 API

# Create local data for each API endpoint that needs pagination
# These modules use "count" to support multiple API calls for pagination

# Primary App Resource Types (paginated)
data "external" "primary_app_resource_types" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    api_url_base = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
}

# Target App Resource Types (paginated)
data "external" "target_app_resource_types" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    api_url_base = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
}

# Primary App Resources (paginated)
data "external" "primary_app_resources" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    # Ensure we only run if primary_resource_type_id is known
    api_url_base = local.primary_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types/${local.primary_resource_type_id}/resources"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
  # Note: The script needs to handle an empty api_url_base gracefully (e.g., return empty list)
}

# Target App Resources (paginated)
data "external" "target_app_resources" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    # Ensure we only run if target_resource_type_id is known
    api_url_base = local.target_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types/${local.target_resource_type_id}/resources"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
  # Note: The script needs to handle an empty api_url_base gracefully
}

# Primary App Entitlements (paginated)
data "external" "primary_app_entitlements" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    api_url_base = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/entitlements"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
}

# Target App Entitlements (paginated)
data "external" "target_app_entitlements" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    api_url_base = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/entitlements"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
}

# Catalogs/Access Profiles (paginated)
data "external" "list_catalogs" {
  program = ["python3", "${path.module}/scripts/fetch_paginated_data.py"]

  query = {
    api_url_base = "${var.c1_server_url}/api/v1/catalogs"
    api_token    = local.access_token
    page_size    = var.api_page_size
  }
}
