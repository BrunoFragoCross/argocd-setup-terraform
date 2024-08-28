terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
  required_version = "1.9.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.64.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}