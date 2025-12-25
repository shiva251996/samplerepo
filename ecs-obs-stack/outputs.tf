output "grafana_url" {
  value = module.grafana.grafana_url
}

output "observability_cluster_name" {
  value = module.cluster.cluster_name
}

output "prometheus_service_name" {
  value = module.prometheus.prometheus_service_name
}

output "loki_internal_endpoint" {
  value = module.loki.loki_internal_url
}

output "prometheus_security_group_id" {
  value = module.prometheus.prometheus_sg_id
}

output "loki_security_group_id" {
  value = module.loki.loki_sg_id
}

output "grafana_admin_password_secret_arn" {
  value = aws_secretsmanager_secret.grafana_admin.arn
}
