terraform {
  required_version = "~> 1.11.0"
  cloud {
    organization = "iiic1"
    workspaces {
      name = "c1-accessprofiles"
    }
  }
  required_providers {
    conductorone = {
      source  = "ConductorOne/conductorone"
      version = "1.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "conductorone" {
  server_url    = var.c1_server_url
  client_id     = var.c1_client_id
  client_secret = var.c1_client_secret
}
