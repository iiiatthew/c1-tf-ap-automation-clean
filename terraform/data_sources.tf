# CSV content is now provided via var.mapping_csv_content
# We'll keep this as a placeholder for compatibility
data "local_file" "mapping_csv" {
  filename = "${path.module}/data/maps.csv"
}

# Get authentication token for API calls
data "http" "conductorone_get_token" {
  url    = "${var.c1_server_url}/auth/v1/token"
  method = "POST"

  request_headers = {
    Content-Type = "application/x-www-form-urlencoded"
  }
  request_body = "grant_type=client_credentials&client_id=${var.c1_client_id}&client_secret=${var.c1_client_secret}"
}

# Get resource types for Primary App 
data "http" "primary_app_resource_types" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get Primary App Resources 
data "http" "primary_app_resources" {
  url             = local.primary_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types/${local.primary_resource_type_id}/resources"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get resource types for Target App  
data "http" "target_app_resource_types" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get Target App Resources 
data "http" "target_app_resources" {
  url             = local.target_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types/${local.target_resource_type_id}/resources"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get Primary App Entitlements 
data "http" "primary_app_entitlements" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/entitlements"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get Target App Entitlements 
data "http" "target_app_entitlements" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/entitlements"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

# Get existing Catalogs (Access Profiles) via HTTP API
data "http" "list_catalogs" {
  url             = "${var.c1_server_url}/api/v1/catalogs"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

