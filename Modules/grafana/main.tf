locals { grafana_port = 3000 }

resource "aws_security_group" "alb" {
  name   = "${var.name_prefix}-grafana-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.grafana_ingress_cidrs
    description = "HTTP"
  }

  dynamic "ingress" {
    for_each = var.grafana_acm_cert_arn != null ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.grafana_ingress_cidrs
      description = "HTTPS"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "grafana_task" {
  name   = "${var.name_prefix}-grafana-task-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = local.grafana_port
    to_port         = local.grafana_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "ALB -> Grafana"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "grafana" {
  name               = "${var.name_prefix}-grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.name_prefix}-grafana-tg"
  port        = local.grafana_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/api/health"
    matcher = "200"
    interval = 15
    timeout  = 5
    healthy_threshold = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_listener" "https" {
  count             = var.grafana_acm_cert_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.grafana.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.grafana_acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_service_discovery_service" "grafana" {
  name = "grafana"
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

resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.name_prefix}-grafana"
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
    },
    {
      name      = "grafana",
      image     = "grafana/grafana:11.0.0",
      essential = true,
      portMappings = [{ containerPort = local.grafana_port, hostPort = local.grafana_port, protocol = "tcp" }],
      secrets = [
        { name = "GF_SECURITY_ADMIN_PASSWORD", valueFrom = var.grafana_admin_secret_arn }
      ],
      environment = [
        { name = "GF_SECURITY_ADMIN_USER", value = "admin" },
        { name = "GF_USERS_ALLOW_SIGN_UP", value = "false" },
        { name = "GF_AUTH_ANONYMOUS_ENABLED", value = "false" }
      ],
      entryPoint = ["sh","-c"],
      command = [<<-EOC
        mkdir -p /etc/grafana/provisioning/datasources
        cat > /etc/grafana/provisioning/datasources/datasources.yaml <<'EOF'
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            access: proxy
            url: ${var.prometheus_internal_url}
            isDefault: true
          - name: Loki
            type: loki
            access: proxy
            url: ${var.loki_internal_url}
        EOF
        /run.sh
      EOC
      ],
      logConfiguration = {
        logDriver = "awsfirelens",
        options = {
          Name  = "loki",
          Host  = "loki.${var.name_prefix}.local",
          Port  = "3100",
          Labels = "{service=\"grafana\",cluster=\"${var.cluster_name}\"}",
          LineFormat = "json"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "grafana" {
  name          = "${var.name_prefix}-grafana"
  cluster       = var.cluster_arn
  launch_type   = "FARGATE"
  desired_count = 1

  task_definition = aws_ecs_task_definition.grafana.arn

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.grafana_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = local.grafana_port
  }

  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
    port         = local.grafana_port
  }

  depends_on = [aws_lb_listener.http]
}
