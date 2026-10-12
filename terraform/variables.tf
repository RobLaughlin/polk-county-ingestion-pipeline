variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID Used to Store Polk County Housing Sales Data"
}

variable "gcp_project_region" {
  type        = string
  description = "The region used in your GCP Project"
}

variable "gcp_project_zone" {
  type        = string
  description = "The zone used in your GCP Project"
}

variable "application_source_path" {
  type        = string
  description = "Optional absolute host path to the uv application. Defaults to this repository's app directory."
  default     = null
}
