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

# DEPRECATED - Kept for backward compatibility (use paginated versions instead)
# These resources are now intentionally kept minimal/empty as they are replaced by the 
# paginated versions in pagination.tf

data "http" "primary_app_resource_types" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "primary_app_resources" {
  url             = local.primary_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/resource_types/${local.primary_resource_type_id}/resources?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "target_app_resource_types" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "target_app_resources" {
  url             = local.target_resource_type_id == null ? "" : "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/resource_types/${local.target_resource_type_id}/resources?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "primary_app_entitlements" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.primary_app_id}/entitlements?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "target_app_entitlements" {
  url             = "${var.c1_server_url}/api/v1/apps/${var.target_app_id}/entitlements?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}

data "http" "list_catalogs" {
  url             = "${var.c1_server_url}/api/v1/catalogs?page_size=1"
  request_headers = { Accept = "application/json", Authorization = "Bearer ${local.access_token}" }
}