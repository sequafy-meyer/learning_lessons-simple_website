provider "aws" {
  region = var.region
}

provider "aws" {
  region = "eu-central-1"
  assume_role {
    role_arn     = var.domain_arn
  }
  alias = "route53"
}