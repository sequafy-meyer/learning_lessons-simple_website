resource "aws_acm_certificate" "lb_cert" {
  count             = var.lb_ssl && var.cert_arn == "" ? 1 : 0
  domain_name       = var.domain
  lifecycle {
    create_before_destroy = true
  }
  validation_method = "DNS"

  tags = merge(
    {
      Name        = "lb-cert"
      Description = "Certificate for load balancer"
    },
    var.tags
  )
}

resource "aws_acm_certificate_validation" "lb_cert" {
  count                   = var.lb_ssl && var.cert_arn == "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.lb_cert.0.arn
  validation_record_fqdns = [
    aws_route53_record.cert_validation.0.fqdn
  ]
}