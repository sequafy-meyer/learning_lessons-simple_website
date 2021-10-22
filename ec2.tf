data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
}

resource "aws_instance" "webnode" {
  ami                    = var.ec2_ami
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  instance_type          = var.ec2_type
  monitoring             = true
  subnet_id              = aws_subnet.private_a.id
  user_data              = templatefile("templates/userdata_webnode.tpl",{
                             bucket_name = local.bucket_name
  })

  vpc_security_group_ids = [ 
    aws_security_group.webserver.id,
    aws_security_group.default.id
  ]

  tags = merge(
    {
      Name        = "My Webserver"
    },
    var.tags,
  )

  depends_on = [
    aws_ssm_parameter.efs_var_www,
    aws_ssm_parameter.db_instance
  ]
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "ec2-role"
  path               = "/terraform/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

resource "aws_iam_role_policy_attachment" "ec2_role_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ssm_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssm_access.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  path = "/terraform/"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "ssm_access" {
  name = "ssm-access"
  path = "/terraform/epo/" 

  policy = templatefile("templates/ec2_policy.tpl",{
            bucket_name = local.bucket_name,
            account_id  = data.aws_caller_identity.current.account_id
  })
}