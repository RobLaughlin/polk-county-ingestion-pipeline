output "gcp_project_id" {
  value       = var.gcp_project_id
  description = "The GCP project ID"
}

output "gcp_bigquery_raw_ingest_id" {
  value       = google_bigquery_dataset.raw.dataset_id
  description = "The GCP BigQuery raw dataset ID"
}

output "gcp_bucket_raw_ingest_id" {
  value       = google_storage_bucket.default.id
  description = "The GCP raw storage bucket ID"
}

output "raw_ingest_source_url" {
  value       = var.raw_ingest_source_url
  description = "The source URL for where to pull the raw CSV sales data"
}