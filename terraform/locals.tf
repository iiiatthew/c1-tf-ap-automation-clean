locals {
  # Parse the CSV content (try base64 first, fall back to direct CSV)
  decoded_csv_content = var.mapping_csv_content_base64 != "" ? base64decode(var.mapping_csv_content_base64) : var.mapping_csv_content
  csv_content         = try(csvdecode(local.decoded_csv_content), csvdecode(var.mapping_csv_content))
  mapping_csv_data    = local.csv_content

  # Get authentication token 
  token_data   = jsondecode(data.http.conductorone_get_token.response_body)
  access_token = local.token_data.access_token

  # Decode API responses 
  # --- Primary App (e.g., Workday)
  primary_app_resource_types_data = try(jsondecode(data.http.primary_app_resource_types.response_body), null)
  primary_resource_type_ids = [
    for item in lookup(local.primary_app_resource_types_data, "list", []) :
    item.appResourceType.id if lower(item.appResourceType.displayName) == lower(var.primary_resource_type_name)
  ]
  primary_resource_type_id       = length(local.primary_resource_type_ids) == 1 ? local.primary_resource_type_ids[0] : null
  primary_app_resources_api_data = try(jsondecode(data.http.primary_app_resources.response_body), null)

  # --- Target App (e.g., GitHub)
  target_app_resource_types_data = try(jsondecode(data.http.target_app_resource_types.response_body), null)
  target_resource_type_ids = [
    for item in lookup(local.target_app_resource_types_data, "list", []) :
    item.appResourceType.id if lower(item.appResourceType.displayName) == lower(var.target_resource_type_name)
  ]
  target_resource_type_id       = length(local.target_resource_type_ids) == 1 ? local.target_resource_type_ids[0] : null
  target_app_resources_api_data = try(jsondecode(data.http.target_app_resources.response_body), null)

  # --- Entitlements & Existing Profiles (Catalogs) ---
  primary_app_entitlements_api_data = try(jsondecode(data.http.primary_app_entitlements.response_body), null)
  target_app_entitlements_api_data  = try(jsondecode(data.http.target_app_entitlements.response_body), null)
  existing_catalogs_data            = try(jsondecode(data.http.list_catalogs.response_body), null)

  # --- Existing Profiles Map --- 
  existing_profiles_by_id_map = {
    for catalog in lookup(local.existing_catalogs_data, "list", []) :
    catalog.requestCatalog.id => catalog.requestCatalog
  }

  # --- Processed/Mapped Data --- 
  primary_app_resources_map = local.primary_app_resources_api_data == null ? {} : {
    for res_response in lookup(local.primary_app_resources_api_data, "list", []) :
    res_response.appResource.id => { id = res_response.appResource.id, display_name = res_response.appResource.displayName }
  }
  primary_app_resources_by_name_map = local.primary_app_resources_api_data == null ? {} : {
    for res_response in lookup(local.primary_app_resources_api_data, "list", []) :
    res_response.appResource.displayName => { id = res_response.appResource.id, display_name = res_response.appResource.displayName }
  }
  target_app_resources_map = local.target_app_resources_api_data == null ? {} : {
    for res_response in lookup(local.target_app_resources_api_data, "list", []) :
    res_response.appResource.displayName => { id = res_response.appResource.id, display_name = res_response.appResource.displayName }
  }
  target_app_entitlements_map = {
    for ent in lookup(local.target_app_entitlements_api_data, "list", []) :
    "${ent.appEntitlement.appResourceId}:${lower(ent.appEntitlement.displayName)}" => { id = ent.appEntitlement.id, display_name = ent.appEntitlement.displayName, app_resource_id = ent.appEntitlement.appResourceId }
  }
  primary_app_enrollment_entitlements_map = {
    for primary_resource_id, primary_resource_details in local.primary_app_resources_map :
    primary_resource_id => [
      for ent in lookup(local.primary_app_entitlements_api_data, "list", []) :
      ent.appEntitlement.id
      if ent.appEntitlement.appResourceId == primary_resource_id && lower(ent.appEntitlement.displayName) == lower("${primary_resource_details.display_name} ${var.enrollment_entitlement_slug}")
    ]
    if length([for ent in lookup(local.primary_app_entitlements_api_data, "list", []) : ent.appEntitlement.id if ent.appEntitlement.appResourceId == primary_resource_id && lower(ent.appEntitlement.displayName) == lower("${primary_resource_details.display_name} ${var.enrollment_entitlement_slug}")]) > 0
  }

  # --- Logic based on CSV --- 
  supervisory_orgs_in_csv = toset([
    for row in local.mapping_csv_data : row.source_resource
  ])

  # Map of Primary App Resources that are ALSO mentioned in the CSV
  managed_resources_map = {
    for id, details in local.primary_app_resources_map :
    id => details if contains(local.supervisory_orgs_in_csv, details.display_name)
  }

  # Identify which managed primary resources need NEW access profiles
  profiles_to_create = {
    for id, details in local.managed_resources_map :
    id => details if !contains(keys(local.existing_profiles_by_id_map), "${details.display_name} Profile")
  }

  # Create unified mappings from CSV data to Target App Entitlement IDs
  target_entitlement_mappings = [
    for row in local.mapping_csv_data : {
      primary_resource_id     = lookup(local.primary_app_resources_by_name_map, row.source_resource, { id = null, display_name = null }).id
      primary_resource_name   = row.source_resource
      target_resource_name    = row.target_resource
      target_entitlement_name = row.target_entitlement
      target_resource_id      = lookup(local.target_app_resources_map, row.target_resource, { id = null, display_name = null }).id
      target_entitlement_id = lookup(local.target_app_entitlements_map,
        "${lookup(local.target_app_resources_map, row.target_resource, { id = null, display_name = null }).id}:${lower(row.target_resource)} ${lower(row.target_entitlement)}",
      { id = null, display_name = null, app_resource_id = null }).id
    }
    # Filter based on main primary map and target maps 
    if lookup(local.primary_app_resources_by_name_map, row.source_resource, null) != null &&
    lookup(local.target_app_resources_map, row.target_resource, null) != null &&
    lookup(local.target_app_entitlements_map,
      "${lookup(local.target_app_resources_map, row.target_resource, { id = null, display_name = null }).id}:${lower(row.target_resource)} ${lower(row.target_entitlement)}",
    { id = null, display_name = null, app_resource_id = null }).id != null
  ]

  # Group Target App Entitlement IDs by Primary Resource ID (for MANAGED resources)
  profile_target_entitlement_groups = {
    for primary_resource_id, primary_resource_details in local.managed_resources_map :
    primary_resource_id => distinct([
      for mapping in local.target_entitlement_mappings :
      mapping.target_entitlement_id if mapping.primary_resource_id == primary_resource_id
    ])
  }

  # Map of ALL MANAGED profile IDs (whether existing or to-be-created)
  all_managed_profile_ids = {
    for managed_resource_id, managed_resource_details in local.managed_resources_map :
    managed_resource_id => contains(keys(local.profiles_to_create), managed_resource_id) ?
    conductorone_access_profile.profile[managed_resource_id].id :
    local.existing_profiles_by_id_map["${managed_resource_details.display_name} Profile"]
  }
}
