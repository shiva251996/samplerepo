output "ecs_execution_role_arn" { value = aws_iam_role.ecs_execution.arn }
output "grafana_task_role_arn"  { value = aws_iam_role.grafana_task.arn }
output "prometheus_task_role_arn" { value = aws_iam_role.prometheus_task.arn }
output "loki_task_role_arn"     { value = aws_iam_role.loki_task.arn }
