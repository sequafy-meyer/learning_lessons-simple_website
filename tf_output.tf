output "ns_zone" {
  value       = var.domain != "" && var.zone_id == "" ? aws_route53_zone.domain.0.name_servers : null
  description = "Nameserver of the domain for registration"
}

output "lb_url" {
  value       = aws_lb.web_lb.dns_name
  description = "FQDN of the loadbalancer"
}