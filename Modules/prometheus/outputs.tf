output "prometheus_sg_id" { value = aws_security_group.prometheus.id }
output "prometheus_internal_url" { value = "http://prometheus.${var.name_prefix}.local:9090" }
output "prometheus_service_name" { value = aws_ecs_service.prometheus.name }
