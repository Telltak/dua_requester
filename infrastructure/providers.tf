terraform {

  required_version = ">= 1.10.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.7.1"
    }
  }

  backend "s3" {
    bucket       = "telltak-terraform-state"
    key          = "dua_requester"
    region       = "eu-west-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = "eu-west-1"

  default_tags {
    tags = {
      Application = "dua_requester"
    }
  }
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"

  default_tags {
    tags = {
      Application = "dua_requester"
    }
  }
}
