output "cluster_name" { value = aws_ecs_cluster.this.name }
output "cluster_arn"  { value = aws_ecs_cluster.this.arn }
output "namespace_id" { value = aws_service_discovery_private_dns_namespace.ns.id }
