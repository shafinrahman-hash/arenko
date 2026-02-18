provider "aws" {
  region = "eu-west-2"

  # Make Terraform stop trying to validate creds / call AWS account APIs
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
}