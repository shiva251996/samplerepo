resource "aws_ecs_task_definition" "prometheus" {
  family                   = "obs-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec.arn

  container_definitions = jsonencode([{
    name  = "prometheus"
    image = "prom/prometheus:latest"
    portMappings = [{
      containerPort = 9090
    }]
  }])
}

resource "aws_ecs_service" "prometheus" {
  name            = "obs-prometheus"
  cluster         = aws_ecs_cluster.obs.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.prometheus.id]
  }
}
