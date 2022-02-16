resource "aws_efs_file_system" "var_www" {
  creation_token = "var-www"

  tags = merge(
    {
      Name        = "var-www"
      Description = "EFS filesystem for var www mount" 
    },
    var.tags
  )
}

resource "aws_efs_mount_target" "var_www" {
  count           = 2
  file_system_id  = aws_efs_file_system.var_www.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_ssm_parameter" "efs_var_www" {
  name  = "/webserver/efs/www"
  description  = "EFS mount target"
  tags = var.tags
  type  = "String"
  value = aws_efs_mount_target.var_www[0].dns_name
}