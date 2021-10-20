resource "aws_eip" "eip_nat" {
  vpc        = true
  depends_on = [aws_internet_gateway.default_igw]
}


resource "aws_nat_gateway" "default_ngw" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.eip_nat.id
  depends_on    = [aws_internet_gateway.default_igw]

  tags = merge(
    {
      Name        = "default-ngw"
      Description = "NAT Gateway for private subnet"
    },
    var.tags
  )
}