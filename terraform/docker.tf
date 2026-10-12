locals {
  application_source_path = var.application_source_path != null ? var.application_source_path : abspath("${path.module}/../ingestion")
}

resource "docker_image" "ingest" {
  name = "polk-county-ingestion:dev"

  build {
    context = abspath("${path.module}/docker-ingest")
  }

  # Source and dependency edits use the bind mount, not an image rebuild.
  triggers = {
    dockerfile   = filesha256("${path.module}/docker-ingest/Dockerfile")
    dockerignore = filesha256("${path.module}/docker-ingest/.dockerignore")
  }
}

resource "docker_volume" "ingest_venv" {
  name = "polk-county-ingestion-venv"
}

resource "docker_container" "ingest" {
  name        = "polk-county-ingestion-dev"
  image       = docker_image.ingest.image_id
  working_dir = "/ingestion"
  init        = true

  env = [
    "GOOGLE_APPLICATION_CREDENTIALS=/secrets/gcp-adc.json",
    "GOOGLE_CLOUD_PROJECT=${var.gcp_project_id}",
  ]

  # The volumes syntax preserves host paths with Docker Desktop's WSL integration.
  volumes {
    host_path      = local.application_source_path
    container_path = "/ingestion"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.ingest_venv.name
    container_path = "/opt/venv"
  }

  volumes {
    host_path = pathexpand(
      "~/.config/gcloud/application_default_credentials.json"
    )
    container_path = "/secrets/gcp-adc.json"
    read_only      = true
  }
}


