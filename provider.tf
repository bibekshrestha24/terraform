terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.24.1"
    }
  }
}

provider "aws" {
  profile = "bibek"
  region  = "us-west-2"
}
