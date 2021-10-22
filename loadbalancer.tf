resource "aws_lb" "web_lb" {
  enable_deletion_protection = true
  internal                   = false
  load_balancer_type         = "application"
  name                       = "web-lb"
  security_groups            = [ aws_security_group.loadbalancer.id ]
  subnets                    = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = merge(
    {
      Name        = "web-lb"
      Description = "Application loadbalancer in front of webserver"
    },
    var.tags
  )
}

resource "aws_lb_listener" "web_listener_https" {
  count             = var.lb_ssl ? 1 : 0
  certificate_arn   = var.cert_arn != "" ? var.cert_arn : aws_acm_certificate.lb_cert.0.arn
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"

  default_action {
    target_group_arn = aws_lb_target_group.web_target.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "web_listener_http_forward" {
  count             = var.lb_ssl ? 1 : 0
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  # Forward to HTTPS (301)
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "web_listener_http" {
  count             = var.lb_ssl ? 0 : 1
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 80
  protocol          = "HTTP"

  # Forward to target group
  default_action {
    target_group_arn = aws_lb_target_group.web_target.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "web_target" {
  name     = "web-targetgroup"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.web_vpc.id
}

resource "aws_lb_target_group_attachment" "web_target_attach" {
  target_group_arn = aws_lb_target_group.web_target.arn
  target_id        = aws_instance.webnode.id
  port             = 8080
}