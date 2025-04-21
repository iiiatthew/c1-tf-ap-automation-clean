# PLACEHOLDER for bundle automation
resource "null_resource" "automation_trigger" {
  for_each = {
    for primary_resource_id, profile_id in local.all_managed_profile_ids :
    primary_resource_id => {
      access_profile_id         = profile_id
      enrollment_entitlement_id = lookup(local.primary_app_enrollment_entitlements_map, primary_resource_id, null) == null ? null : local.primary_app_enrollment_entitlements_map[primary_resource_id][0]
    }
    if lookup(local.primary_app_enrollment_entitlements_map, primary_resource_id, null) != null
  }

  triggers = {
    access_profile_id         = each.value.access_profile_id
    enrollment_entitlement_id = each.value.enrollment_entitlement_id
    always_run                = timestamp()
  }
  depends_on = [conductorone_access_profile_requestable_entries.profile_entries]
}

# data source for bundle automation
data "http" "set_automation" {
  for_each = null_resource.automation_trigger

  url    = "${var.c1_server_url}/api/v1/catalogs/${each.value.triggers.access_profile_id}/bundle_automation"
  method = "POST"

  request_headers = {
    Accept        = "application/json"
    Content-Type  = "application/json"
    Authorization = "Bearer ${local.access_token}"
  }

  request_body = jsonencode({
    createTasks = true
    enabled     = true
    entitlements = {
      entitlementRefs = [
        {
          appId = var.primary_app_id
          id    = each.value.triggers.enrollment_entitlement_id
        }
      ]
    }
  })

  depends_on = [
    conductorone_access_profile.profile,
    conductorone_access_profile_requestable_entries.profile_entries
  ]
}
