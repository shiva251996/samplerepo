variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "name_prefix" {
  type    = string
  default = "obs"
}

# Reuse ONLY
variable "vpc_id" {
  type = string
}

# Public subnets (ALB)
variable "public_subnet_ids" {
  type = list(string)
}

# Private subnets (tasks). Use true private subnets in prod.
variable "private_subnet_ids" {
  type = list(string)
}

# Grafana public access (ALB only)
variable "grafana_ingress_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

# Optional HTTPS
variable "grafana_acm_cert_arn" {
  type    = string
  default = null
}

# Prometheus ECS discovery across clusters (same VPC)
# Example: ["dev-cluster", "prod-cluster"]
variable "prometheus_discover_cluster_names" {
  type    = list(string)
  default = []
}

# Loki retention
variable "loki_retention_days" {
  type    = number
  default = 30
}
