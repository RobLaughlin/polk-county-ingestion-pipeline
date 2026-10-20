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

variable "raw_ingest_bucket_name" {
  type        = string
  description = "Identifier for the GCP bucket to store the raw ingest data"
  default     = "polk_county_bucket_ingest_data_raw"
}

variable "raw_ingest_dataset_name" {
  type        = string
  description = "Identifier for the GCP BQ dataset to store the raw ingest data"
  default     = "polk_county_dataset_ingest_data_raw"
}

variable "raw_ingest_source_url" {
  type        = string
  description = "The source URL for where to pull the raw CSV sales data"
  default     = "https://www.assess.co.polk.ia.us/info/web/exports/res/sales/polk"
}

variable "transform_dataset_name" {
  type        = string
  description = "Identifier for the GCP BQ dataset to store the transformed data"
  default     = "polk_county_dataset_ingest_data"
}