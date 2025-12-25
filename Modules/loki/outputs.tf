output "loki_sg_id" { value = aws_security_group.loki.id }
output "loki_internal_url" { value = "http://loki.${var.name_prefix}.local:3100" }
output "loki_internal_host" { value = "loki.${var.name_prefix}.local" }
