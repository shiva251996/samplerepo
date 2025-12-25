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
  description = "CIDR allowed to access Grafana via ALB (e.g. your office IP)"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN in the same region for HTTPS"
  type        = string
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}
