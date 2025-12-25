variable "name_prefix" { type = string }
variable "aws_region"  { type = string }
variable "vpc_id"      { type = string }
variable "vpc_cidr"    { type = string }
variable "private_subnet_ids" { type = list(string) }

variable "cluster_arn"  { type = string }
variable "cluster_name" { type = string }
variable "namespace_id" { type = string }

variable "execution_role_arn" { type = string }
variable "task_role_arn"      { type = string }

variable "loki_bucket_name" { type = string }
variable "loki_retention_days" { type = number }
