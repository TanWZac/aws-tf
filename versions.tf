terraform {
  required_version = ">= 1.9.0"

  cloud {
    organization = "tanwzac-org"

    workspaces {
      name = "aws-tf"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
