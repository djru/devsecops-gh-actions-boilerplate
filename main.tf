terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "floci" # Dummy credential accepted by Floci
  secret_key                  = "floci" # Dummy credential accepted by Floci
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Redirect real AWS APIs to the local Floci container instance
  endpoints {
    s3           = "http://localhost:4566"
    dynamodb     = "http://localhost:4566"
    iam          = "http://localhost:4566"
    sts          = "http://localhost:4566"
    ecs          = "http://localhost:4566"
  }
}

# Example resource to verify the Terraform loop works against Floci
resource "aws_s3_bucket" "test_bucket" {
  bucket = "poc-starlette-deployment-bucket"
}