variable "region" {
  description = "Region where TF will be deployed to"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Bunch of tags to be applied to all ressources"
  type        = map(any)
}

variable "vpc_cidr" {
  description = "CIDR block for our VPC"
  type        = string
  default     = "192.168.0.0/24"
}

variable "ec2_type" {
  description = "Type of the instance"
  type        = string
  default     = "t4g.nano"
}

variable "domain" {
  description = "Domain for deployment"
  type        = string
}

variable "lb_ssl" {
  description = "If set to true, ssl will be implemented"
  type        = bool
  default     = false
}

variable "zone_ns" {
  description = "ID of the parent domain"
  type        = string
  default     = ""
}

variable "zone_id" {
  description = "ID of domain FQDN will be created in"
  type        = string
  default     = ""
}

variable "domain_arn" {
  description = "ARN of role which has sufficient rights to manage domain if domain is handled in different account"
  type        = string
  default     = ""
}

variable "cert_arn" {
  description = "ARN of an existing certificate"
  type        = string
  default     = ""
}

variable "ec2_ami" {
  description = "ID of the selected AMI"
  type        = string
}

variable "ec2_scale" {
  description = "Activate usage of EC2 autoscaling"
  type        = bool
  default     = false
}