resource "aws_ecs_task_definition" "grafana" {
  family                   = "obs-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([{
    name  = "grafana"
    image = "grafana/grafana:latest"
    portMappings = [{
      containerPort = 3000
    }]
    environment = [
      { name = "GF_SECURITY_ADMIN_PASSWORD", value = "Admin@123" }
    ]
  }])
}

resource "aws_ecs_service" "grafana" {
  name            = "obs-grafana-${random_pet.suffix.id}"
  cluster         = aws_ecs_cluster.obs.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.grafana.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"   # must match container definition name
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.https]
}
