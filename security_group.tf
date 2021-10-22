resource "aws_security_group" "default" {
  name              = "default-sg"
  description       = "Default SG to allow traffic to ext"
  vpc_id            = aws_vpc.web_vpc.id

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "default-sg"
      Description = "Default SG to allow traffic to ext"
    },
    var.tags
  )
}

resource "aws_security_group" "efs" {
  name              = "efs-access"
  description       = "Allow traffic to efs mounts"
  vpc_id            = aws_vpc.web_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "TCP"
    security_groups = [aws_security_group.webserver.id]
  }

  tags = merge(
    {
      Name        = "efs-access"
      Description = "Allow traffic to efs mounts"
    },
    var.tags
  )
}

resource "aws_security_group" "mysql" {
  name              = "mysql-access"
  description       = "Allow traffic to the MySQL database"
  vpc_id            = aws_vpc.web_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "TCP"
    security_groups = [aws_security_group.webserver.id]
  }

  tags = merge(
    {
      Name        = "mysql-access"
      Description = "Allow traffic to the MySQL database"
    },
    var.tags
  )
}

resource "aws_security_group" "webserver" {
  name              = "webserver-access"
  description       = "Allow traffic to the webserver"
  vpc_id            = aws_vpc.web_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "TCP"
    security_groups = [aws_security_group.loadbalancer.id]
  }

  tags = merge(
    {
      Name        = "webserver-access"
      Description = "Allow traffic to the webserver"
    },
    var.tags
  )
}

resource "aws_security_group" "loadbalancer" {
  name              = "loadbalancer-access"
  description       = "Allow traffic to the load balancer"
  vpc_id            = aws_vpc.web_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "loadbalancer-access"
      Description = "Allow traffic to the load balancer"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "loadbalancer_to_webserver" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.webserver.id
  security_group_id        = aws_security_group.loadbalancer.id
}