provider "aws" {
  region = var.region
}

provider "aws" {
region = "eu-central-1"
 assume_role {
    role_arn     = "arn:aws:iam::699444064213:role/route53.create_zone"
  }
  alias = "route53"
}