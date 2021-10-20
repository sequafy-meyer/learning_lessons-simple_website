resource "aws_vpc" "web_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = merge(
    {
      Name        = "default-vpc"
      Description = "Default VPC for our Website"
    },
    var.tags
  )
}