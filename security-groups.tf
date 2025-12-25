resource "random_pet" "suffix" {
  length = 2
}

resource "aws_security_group" "grafana" {
  name   = "obs-grafana-sg"
  vpc_id = var.vpc_id

  ingress {
    description    = "Allow ALB to reach Grafana"
    from_port      = 3000
    to_port        = 3000
    protocol       = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "loki" {
  name   = "obs-loki-sg-${random_pet.suffix.id}"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3100
    to_port         = 3100
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prometheus" {
  name   = "obs-prometheus-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.grafana.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
