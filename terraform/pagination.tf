# Pagination module for ConductorOne API
# This file contains utilities for fetching paginated data from the C1 API

locals {
  # Function to extract nextPageToken from API response
  extract_next_page_token = function(response_body) {
    try(
      jsondecode(response_body).nextPageToken,
      ""
    )
  }
}

# Create local data for each API endpoint that needs pagination
# These modules use "count" to support multiple API calls for pagination

# Primary App Resource Types (paginated)
data "http" "paginated_primary_app_resource_types" {
  count = 20 # Set a reasonable upper limit on pagination loops

  url = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.primary_resource_types_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.primary_resource_types_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Target App Resource Types (paginated)
data "http" "paginated_target_app_resource_types" {
  count = 20 # Set a reasonable upper limit on pagination loops

  url = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.target_resource_types_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.target_resource_types_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Primary App Resources (paginated)
data "http" "paginated_primary_app_resources" {
  count = local.primary_resource_type_id == null ? 0 : 20 # Skip if resource type not found

  url = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types/${local.primary_resource_type_id}/resources?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.primary_resources_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.primary_resources_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Target App Resources (paginated)
data "http" "paginated_target_app_resources" {
  count = local.target_resource_type_id == null ? 0 : 20 # Skip if resource type not found

  url = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types/${local.target_resource_type_id}/resources?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.target_resources_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.target_resources_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Primary App Entitlements (paginated)
data "http" "paginated_primary_app_entitlements" {
  count = 20 # Set a reasonable upper limit on pagination loops

  url = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/entitlements?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.primary_entitlements_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.primary_entitlements_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Target App Entitlements (paginated)
data "http" "paginated_target_app_entitlements" {
  count = 20 # Set a reasonable upper limit on pagination loops

  url = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/entitlements?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.target_entitlements_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.target_entitlements_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}

# Catalogs/Access Profiles (paginated)
data "http" "paginated_list_catalogs" {
  count = 20 # Set a reasonable upper limit on pagination loops

  url = "${var.c1_server_url}/api/v1/catalogs?page_size=${var.api_page_size}${count.index == 0 ? "" : "&page_token=${local.catalogs_next_tokens[count.index - 1]}"}"
  
  request_headers = { 
    Accept = "application/json", 
    Authorization = "Bearer ${local.access_token}" 
  }

  # Stop making further calls if we don't have a next token
  lifecycle {
    precondition {
      condition     = count.index == 0 || local.catalogs_next_tokens[count.index - 1] != ""
      error_message = "No more pages to fetch."
    }
  }
}