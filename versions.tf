terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Remote state in S3. Settings live per environment, e.g. dev/backend.hcl:
  #   terraform init -backend-config=dev/backend.hcl
  backend "s3" {}
}

provider "aws" {
  region = var.region

  # Every resource gets these tags, so the lab's cost is easy to find in Cost Explorer.
  default_tags {
    tags = {
      Project   = "eks-lab"
      ManagedBy = "terraform"
    }
  }
}
