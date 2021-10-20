resource "aws_internet_gateway" "default_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = merge(
    {
      Name        = "default-igw"
      Description = "Internet Gateway to enable internet connectivity"
    },
    var.tags
  )
}