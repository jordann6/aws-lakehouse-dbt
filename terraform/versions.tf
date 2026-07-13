terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Local backend on purpose: ephemeral deploy-demo-destroy infra, state lives
  # with the code and disappears on teardown.
  backend "local" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "aws-lakehouse-dbt"
      ManagedBy = "terraform"
    }
  }
}
