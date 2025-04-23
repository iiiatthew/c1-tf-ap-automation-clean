# Create/Update/Delete profiles based DIRECTLY on managed resources map (derived from CSV)
resource "conductorone_access_profile" "profile" {
  for_each = local.managed_resources_map

  display_name                      = "${each.value.display_name} Profile"
  description                       = "Access profile for primary resource ${each.value.display_name}"
  published                         = true
  enrollment_behavior               = "REQUEST_CATALOG_ENROLLMENT_BEHAVIOR_BYPASS_ENTITLEMENT_REQUEST_POLICY"
  request_bundle                    = false
  unenrollment_behavior             = "REQUEST_CATALOG_UNENROLLMENT_BEHAVIOR_REVOKE_UNJUSTIFIED"
  unenrollment_entitlement_behavior = "REQUEST_CATALOG_UNENROLLMENT_ENTITLEMENT_BEHAVIOR_BYPASS"
  visible_to_everyone               = false
}

# Configure requestable entries based on CSV-derived groups
resource "conductorone_access_profile_requestable_entries" "profile_entries" {
  for_each = local.profile_target_entitlement_groups

  catalog_id = local.all_managed_profile_ids[each.key]

  create_requests = false
  app_entitlements = [
    for entitlement_id in each.value : {
      app_id = var.target_app_id
      id     = entitlement_id
    }
  ]
}

# Attach Grant Policy to managed profiles
resource "conductorone_app_entitlement" "profile_policy_attachment" {
  for_each = conductorone_access_profile.profile

  app_id          = var.conductorone_app_id
  id              = each.value.id
  grant_policy_id = var.ap_request_policy_id
}
