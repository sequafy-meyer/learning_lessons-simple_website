data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count  = 2
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,0),1,count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(
    {
      Name        = format("public-subnet-%s", substr(element(data.aws_availability_zones.available.names, count.index), -2, -2)),
      Description = format("Public subnet in AZ %s", element(data.aws_availability_zones.available.names, count.index))
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  count  = 2
  vpc_id = aws_vpc.web_vpc.id

  cidr_block        = cidrsubnet(cidrsubnet(aws_vpc.web_vpc.cidr_block,1,1),1,count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge(
    {
      Name        = format("private-subnet-%s", substr(element(data.aws_availability_zones.available.names, count.index), -2, -2)),
      Description = format("Private subnet in AZ %s", element(data.aws_availability_zones.available.names, count.index))
    },
    var.tags
  )
}