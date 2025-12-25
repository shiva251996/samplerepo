resource "aws_security_group" "alb" {
  name        = "obs-alb-sg-${random_pet.suffix.id}"
  description = "ALB SG (allow HTTP from allowed CIDR)"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDR"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "obs-alb-sg"
  }
}

resource "aws_lb" "app" {
  name               = "obs-alb-${random_pet.suffix.id}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "grafana" {
  name        = "obs-grafana-tg-${random_pet.suffix.id}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    # Use Grafana's health endpoint which returns a 200 when healthy
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }
}

# HTTP listener (used when no certificate is provided)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}