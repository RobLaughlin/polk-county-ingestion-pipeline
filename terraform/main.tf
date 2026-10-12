terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_project_region
  zone    = var.gcp_project_zone
}

provider "docker" {}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}
