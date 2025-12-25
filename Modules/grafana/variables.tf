variable "name_prefix" {
	type = string
}

variable "aws_region" {
	type = string
}

variable "vpc_id" {
	type = string
}

variable "vpc_cidr" {
	type = string
}

variable "public_subnet_ids" {
	type = list(string)
}

variable "private_subnet_ids" {
	type = list(string)
}

variable "grafana_ingress_cidrs" {
	type = list(string)
}

variable "grafana_acm_cert_arn" {
	type    = string
	default = null
}

variable "cluster_arn" {
	type = string
}

variable "cluster_name" {
	type = string
}

variable "namespace_id" {
	type = string
}

variable "execution_role_arn" {
	type = string
}

variable "task_role_arn" {
	type = string
}

variable "grafana_admin_secret_arn" {
	type = string
}

variable "prometheus_internal_url" {
	type = string
}

variable "loki_internal_url" {
	type = string
}

variable "prometheus_sg_id" {
	type = string
}

variable "loki_sg_id" {
	type = string
}
