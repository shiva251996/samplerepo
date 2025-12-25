output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "grafana_url" {
  value = "http://${aws_lb.app.dns_name}:80/"
}

output "grafana_admin_password" {
  description = "Grafana admin password (insecure to expose in outputs)"
  value       = var.grafana_admin_password
}
