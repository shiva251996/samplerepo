resource "aws_ecs_task_definition" "loki" {
  family                   = "obs-loki"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_exec.arn
  task_role_arn            = aws_iam_role.loki_task.arn

  container_definitions = jsonencode([{
    name  = "loki"
    image = "grafana/loki:2.9.8"
    portMappings = [{
      containerPort = 3100
    }]
    command = [
      "-config.file=/etc/loki/local-config.yaml"
    ]
  }])
}

resource "aws_ecs_service" "loki" {
  name            = "obs-loki-${random_pet.suffix.id}"
  cluster         = aws_ecs_cluster.obs.id
  task_definition = aws_ecs_task_definition.loki.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = [aws_security_group.loki.id]
  }
}
