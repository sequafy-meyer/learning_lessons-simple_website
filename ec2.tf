resource "aws_instance" "webnode" {
  count                  = var.ec2_scale ? 0 : 1
  ami                    = var.ec2_ami
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  instance_type          = var.ec2_type
  monitoring             = true
  subnet_id              = aws_subnet.private[count.index].id
  user_data              = templatefile("templates/userdata_webnode.tpl",{
                             bucket_name = local.bucket_name
  })

  vpc_security_group_ids = [ 
    aws_security_group.webserver.id,
    aws_security_group.default.id
  ]

  tags = merge(
    {
      Name        = "Webserver"
    },
    var.tags,
  )

  depends_on = [
    aws_ssm_parameter.efs_var_www,
    aws_ssm_parameter.db_instance
  ]
}

# Autoscaling
resource "aws_launch_configuration" "webserver" {
  count                = var.ec2_scale ? 1 : 0
  name                 = "webserver"

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  image_id             = var.ec2_ami
  instance_type        = var.ec2_type
  security_groups      = [ 
    aws_security_group.webserver.id,
    aws_security_group.default.id
  ]

  user_data            = templatefile("templates/userdata_webnode.tpl",{
    bucket_name = local.bucket_name
  })

  depends_on = [
    aws_ssm_parameter.efs_var_www,
    aws_ssm_parameter.db_instance
  ]
}

resource "aws_autoscaling_group" "webserver" {
  count                = var.ec2_scale ? 1 : 0
  name                 = "webserver"

  min_size             = 2
  desired_capacity     = 2
  max_size             = 4
  
  launch_configuration = aws_launch_configuration.webserver[0].name
  vpc_zone_identifier  = aws_subnet.private.*.id

  health_check_type    = "ELB"

  target_group_arns = [
    aws_lb_target_group.web_target.id
  ]

  tag {
    key                 = "Name"
    value               = "Webserver"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
		
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
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
  path = "/terraform/" 

  policy = templatefile("templates/ec2_policy.tpl",{
            bucket_name = local.bucket_name,
            account_id  = data.aws_caller_identity.current.account_id
  })
}