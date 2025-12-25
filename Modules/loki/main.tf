locals {
  loki_port = 3100
  loki_host = "loki.${var.name_prefix}.local"
}

resource "aws_security_group" "loki" {
  name        = "${var.name_prefix}-loki-sg"
  description = "Loki private"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.loki_port
    to_port     = local.loki_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Loki ingest from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "loki" {
  name = "loki"
  dns_config {
    namespace_id   = var.namespace_id
    routing_policy = "MULTIVALUE"
    dns_records {
      type = "A"
      ttl  = 10
    }
  }
  health_check_custom_config { failure_threshold = 1 }
}

resource "aws_ecs_task_definition" "loki" {
  family                   = "${var.name_prefix}-loki"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
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
      # No awslogs here => no CloudWatch dependency
    },
    {
      name      = "loki",
      image     = "grafana/loki:2.9.8",
      essential = true,
      portMappings = [
        { containerPort = local.loki_port, hostPort = local.loki_port, protocol = "tcp" }
      ],
      entryPoint = ["sh","-c"],
      command = [<<-EOC
        cat > /etc/loki/config.yaml <<'EOF'
        auth_enabled: false
        server:
          http_listen_port: 3100

        common:
          path_prefix: /loki
          replication_factor: 1
          ring:
            kvstore:
              store: inmemory
          storage:
            s3:
              bucketnames: ${var.loki_bucket_name}
              region: ${var.aws_region}

        schema_config:
          configs:
            - from: 2024-01-01
              store: boltdb-shipper
              object_store: s3
              schema: v12
              index:
                prefix: index_
                period: 24h

        storage_config:
          boltdb_shipper:
            active_index_directory: /loki/index
            cache_location: /loki/cache
            shared_store: s3

        compactor:
          working_directory: /loki/compactor
          shared_store: s3
          retention_enabled: true

        limits_config:
          retention_period: ${var.loki_retention_days * 24}h
        EOF

        /usr/bin/loki -config.file=/etc/loki/config.yaml
      EOC
      ],
      logConfiguration = {
        logDriver = "awsfirelens",
        options = {
          Name  = "loki",
          Host  = "127.0.0.1",
          Port  = "3100",
          Labels = "{service=\"loki\",cluster=\"${var.cluster_name}\"}",
          LineFormat = "json"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "loki" {
  name          = "${var.name_prefix}-loki"
  cluster       = var.cluster_arn
  launch_type   = "FARGATE"
  desired_count = 1

  task_definition = aws_ecs_task_definition.loki.arn

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.loki.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.loki.arn
    port         = local.loki_port
  }
}
