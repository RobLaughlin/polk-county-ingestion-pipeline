resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_project_service" "bigquery_api" {
  service                    = "bigquery.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "random_id" "raw_ingest_suffix" {
  byte_length = 4 # Generates 4 random bytes (results in 8 hex characters)
}

resource "google_storage_bucket" "default" {
  name                        = "${var.raw_ingest_bucket_name}_${random_id.raw_ingest_suffix.hex}"
  location                    = "US"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_bigquery_dataset" "raw" {
  dataset_id                  = "${var.raw_ingest_dataset_name}_${random_id.raw_ingest_suffix.hex}"
  friendly_name               = "Raw Ingestion Data"
  description                 = "Raw Polk County sales data"
  location                    = "US"
  default_table_expiration_ms = null

  # Ensures Terraform enables the API before attempting to create the dataset
  depends_on = [
    google_project_service.bigquery_api
  ]
}