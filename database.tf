# # aws secretsmanager create-secret --name "db/credentials" --description "MySQL server credentials" --secret-string '{"username": "dbruth", "password": "s3hrg3h31m3sP@ssw0rd"}'
data "aws_secretsmanager_secret" "rds_cred" {
  name ="db/credentials"
}

data "aws_secretsmanager_secret_version" "rds_cred" {
    secret_id = data.aws_secretsmanager_secret.rds_cred.id
}

locals {
  rds_cred = jsondecode(
    data.aws_secretsmanager_secret_version.rds_cred.secret_string
  )
}

resource "aws_db_subnet_group" "mysql_group" {
  name       = "mysql-subnet-group"
  subnet_ids = [ aws_subnet.private_a.id, aws_subnet.private_b.id ]

  tags = merge(
    {
      Name        = "mysql-subnet-group"
      Description = "Group of subnets for MySQL instance"
    },
    var.tags
  )
}

resource "aws_db_instance" "mysqldb" {
  allocated_storage           = 5
  allow_major_version_upgrade = true
  db_subnet_group_name        = aws_db_subnet_group.mysql_group.name
  engine                      = "mysql"
  engine_version              = "5.7.34"
  identifier                  = "mysqldb"
  instance_class              = "db.t3.micro"
  name                        = "mysqldb"
  username                    = local.rds_cred.username
  parameter_group_name        = aws_db_parameter_group.default.name
  password                    = local.rds_cred.password
  skip_final_snapshot         = true
  storage_type                = "standard"
  vpc_security_group_ids      = [aws_security_group.mysql.id]

  tags = merge(
    {
      Name        = "mysqldb"
      Description = "MySQL database instance"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "db_instance" {
  name  = "/webserver/db/fqdn"
  description  = "FQDN of the RDS instance"
  tags = var.tags
  type  = "String"
  value = aws_db_instance.mysqldb.address
}

resource "aws_db_parameter_group" "default" {
  name   = "mysql-parameter-group"
  family = "mysql5.7"

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8"
  }

  parameter {
    name  = "character_set_filesystem"
    value = "utf8"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  tags = merge(
    {
      Name        = "mysql-parameter-group"
      Description = "MySQL parameter group"
    },
    var.tags
  )
}