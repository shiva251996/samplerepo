variable "region" {
  default = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "private_subnets" {
  default = [
    "subnet-000c4f09fd19947ca",
    "subnet-02bf3d817dfe863f8"
  ]
}

variable "allowed_cidr" {
  description = "CIDR allowed to access Grafana via ALB (e.g. your office IP). Default 0.0.0.0/0 (insecure)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "certificate_arn" {
  description = "ACM certificate ARN in the same region for HTTPS. Leave empty to use HTTP only."
  type        = string
  default     = ""
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}

variable "grafana_admin_password" {
  description = "Grafana admin password (avoid hardcoding in production)"
  type        = string
  default     = "Admin@123"
}
