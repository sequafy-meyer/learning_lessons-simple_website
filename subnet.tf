data "aws_availability_zones" "available" {}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,0),1,0)
  availability_zone = element(data.aws_availability_zones.available.names, var.az_index)

  tags = merge(
    {
      Name        = format("public-subnet-%s", substr(element(data.aws_availability_zones.available.names, var.az_index), -2, -2)),
      Description = format("Public subnet in AZ %s", element(data.aws_availability_zones.available.names, var.az_index))
    },
    var.tags
  )
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,0),1,1)
  availability_zone = element(data.aws_availability_zones.available.names, var.az_index + 1)

  tags = merge(
    {
      Name        = format("public-subnet-%s", substr(element(data.aws_availability_zones.available.names, var.az_index +1), -2, -2)),
      Description = format("Public subnet in AZ %s", element(data.aws_availability_zones.available.names, var.az_index +1))
    },
    var.tags
  )
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,1),1,0)
  availability_zone = element(data.aws_availability_zones.available.names, var.az_index)

  tags = merge(
    {
      Name        = format("private-subnet-%s", substr(element(data.aws_availability_zones.available.names, var.az_index), -2, -2)),
      Description = format("Private subnet in AZ %s", element(data.aws_availability_zones.available.names, var.az_index))
    },
    var.tags
  )
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,1),1,1)
  availability_zone = element(data.aws_availability_zones.available.names, var.az_index + 1)

  tags = merge(
    {
      Name        = format("private-subnet-%s", substr(element(data.aws_availability_zones.available.names, var.az_index +1 ), -2, -2)),
      Description = format("Private subnet in AZ %s", element(data.aws_availability_zones.available.names, var.az_index + 1))
    },
    var.tags
  )
}