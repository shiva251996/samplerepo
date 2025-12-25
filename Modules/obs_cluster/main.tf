resource "aws_ecs_cluster" "this" {
  name = "${var.name_prefix}-cluster"
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name = "${var.name_prefix}.local"
  vpc  = var.vpc_id
}
