locals {
  prom_port = 9090
  clusters_to_discover = length(var.discover_cluster_names) > 0 ? var.discover_cluster_names : [var.cluster_name]
}

resource "aws_security_group" "prometheus" {
  name        = "${var.name_prefix}-prometheus-sg"
  description = "Prometheus private"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.prom_port
    to_port     = local.prom_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Prometheus UI inside VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "prometheus" {
  name = "prometheus"
  dns_config {
    namespace_id = var.namespace_id
    routing_policy = "MULTIVALUE"
    dns_records { type = "A", ttl = 10 }
  }
  health_check_custom_config { failure_threshold = 1 }
}

resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.name_prefix}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "log_router",
      image     = "grafana/fluent-bit-plugin-loki:latest",
      essential = true,
      memoryReservation = 128,
      firelensConfiguration = {
        type = "fluentbit",
        options = { "enable-ecs-log-metadata" = "true" }
      }
    },
    {
      name      = "prometheus",
      image     = "prom/prometheus:v2.51.2",
      essential = true,
      portMappings = [
        { containerPort = local.prom_port, hostPort = local.prom_port, protocol = "tcp" }
      ],
      entryPoint = ["sh","-c"],
      command = [<<-EOC
        cat > /etc/prometheus/prometheus.yml <<'EOF'
        global:
          scrape_interval: 15s
          evaluation_interval: 15s

        scrape_configs:
          - job_name: "ecs-fargate"
            ecs_sd_configs:
              - region: ${var.aws_region}
                refresh_interval: 30s
                clusters:
        %{ for c in local.clusters_to_discover ~}
                  - ${c}
        %{ endfor ~}

            relabel_configs:
              - source_labels: [__meta_ecs_container_port_name]
                regex: metrics
                action: keep

              - source_labels: [__meta_ecs_task_private_ip, __meta_ecs_container_port_number]
                separator: ':'
                target_label: __address__
                replacement: '$1:$2'

              - target_label: __metrics_path__
                replacement: /metrics

              - source_labels: [__meta_ecs_cluster]
                target_label: ecs_cluster
              - source_labels: [__meta_ecs_service_name]
                target_label: ecs_service
              - source_labels: [__meta_ecs_task_definition_family]
                target_label: task_family
        EOF

        /bin/prometheus \
          --config.file=/etc/prometheus/prometheus.yml \
          --storage.tsdb.path=/prometheus \
          --web.listen-address=:${local.prom_port}
      EOC
      ],
      logConfiguration = {
        logDriver = "awsfirelens",
        options = {
          Name  = "loki",
          Host  = "${var.loki_internal_host}",
          Port  = tostring(var.loki_internal_port),
          Labels = "{service=\"prometheus\",cluster=\"${var.cluster_name}\"}",
          LineFormat = "json"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "prometheus" {
  name          = "${var.name_prefix}-prometheus"
  cluster       = var.cluster_arn
  launch_type   = "FARGATE"
  desired_count = 1

  task_definition = aws_ecs_task_definition.prometheus.arn

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.prometheus.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.prometheus.arn
    port         = local.prom_port
  }
}
