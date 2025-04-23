variable "mapping_csv_content" {
  description = "Content of the mapping CSV"
  type        = string
  default     = ""
}

variable "mapping_csv_content_base64" {
  description = "Base64-encoded content of the mapping CSV"
  type        = string
  default     = ""
}

variable "c1_server_url" {
  description = "ConductorOne server URL"
  type        = string
  default     = "https://yourtenantname.conductor.one"
}

variable "c1_client_id" {
  description = "ConductorOne client ID"
  type        = string
}

variable "c1_client_secret" {
  description = "ConductorOne client secret"
  type        = string
  sensitive   = true
}

variable "primary_app_id" {
  description = "Primary application ID"
  type        = string
  default     = "your-primary-app-id"
}

variable "target_app_id" {
  description = "Target application ID"
  type        = string
  default     = "your-target-app-id"
}

variable "primary_resource_type_name" {
  description = "The exact display name of the Resource Type in the Primary App to manage (e.g., 'supervisory organization')."
  type        = string
  default     = "supervisory organization"
}

variable "target_resource_type_name" {
  description = "The exact display name of the Resource Type in the Target App being mapped (e.g., 'repository')."
  type        = string
  default     = "repository"
}

variable "enrollment_entitlement_slug" {
  description = "The slug used to construct the enrollment entitlement display name (e.g., 'member' results in '<Resource Name> member')."
  type        = string
  default     = "member"
}

variable "conductorone_app_id" {
  description = "The static App ID for the ConductorOne application itself, used for attaching policies."
  type        = string
  default     = "2fsgTvxP0DVTsNXEUBI7hOe0l5A"
}

variable "ap_request_policy_id" {
  description = "Access request policy ID"
  type        = string
  default     = "2ouELGvYbcY6WZJYB52iPi0P1Wm"
}

variable "api_page_size" {
  description = "Number of results to return per page for API requests (10-100)"
  type        = number
  default     = 100
}
