output "grafana_url" { value = "http://${aws_lb.grafana.dns_name}" }
output "grafana_task_sg_id" { value = aws_security_group.grafana_task.id }
