# if domain is set and zone id is empty we need to create a new zone
resource "aws_route53_zone" "domain" {
  count = var.domain != "" && var.zone_id == "" ? 1 : 0
  name  = var.domain

  tags = merge(
    {
      Name        = "domain"
      Description = "Route53 zone for deployment"
    },
    var.tags
  )
}

resource "aws_route53_record" "domain_ns" {
  # Destination zone for NS records is set and records will be deployed to newly created zone
  count   = var.zone_ns != "" && var.zone_id == "" ? 1 : 0
  zone_id = var.zone_ns
  name    = var.domain
  type    = "NS"
  ttl     = "30"

  records = [
    aws_route53_zone.domain.0.name_servers.0,
    aws_route53_zone.domain.0.name_servers.1,
    aws_route53_zone.domain.0.name_servers.2,
    aws_route53_zone.domain.0.name_servers.3
  ]

  provider = aws.route53
}


# if domain is set and zone created we will create the cert records
resource "aws_route53_record" "cert_validation" {
  count   = var.lb_ssl && var.cert_arn == "" ? 1 : 0
  name    = tolist(aws_acm_certificate.lb_cert.0.domain_validation_options).0.resource_record_name
  records = [ tolist(aws_acm_certificate.lb_cert.0.domain_validation_options).0.resource_record_value ]
  ttl     = 30
  type    = tolist(aws_acm_certificate.lb_cert.0.domain_validation_options).0.resource_record_type
  zone_id = var.zone_id != "" ? var.zone_id : aws_route53_zone.domain.0.id
}

resource "aws_route53_record" "lb_record" {
  zone_id = var.zone_id != "" ? var.zone_id : aws_route53_zone.domain.0.id
  name    = var.domain
  type    = "A"

  alias {
    name                   = aws_lb.web_lb.dns_name
    zone_id                = aws_lb.web_lb.zone_id
    evaluate_target_health = true
  }
}