data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name_prefix}-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role      = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grafana task role (SecretsManager read)
resource "aws_iam_role" "grafana_task" {
  name               = "${var.name_prefix}-grafana-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "grafana_secrets" {
  statement {
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.grafana_admin_secret_arn]
  }
}

resource "aws_iam_policy" "grafana_secrets" {
  name   = "${var.name_prefix}-grafana-secrets"
  policy = data.aws_iam_policy_document.grafana_secrets.json
}

resource "aws_iam_role_policy_attachment" "grafana_secrets_attach" {
  role       = aws_iam_role.grafana_task.name
  policy_arn  = aws_iam_policy.grafana_secrets.arn
}

# Prometheus task role (ECS discovery)
resource "aws_iam_role" "prometheus_task" {
  name               = "${var.name_prefix}-prometheus-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "prometheus_discovery" {
  statement {
    effect = "Allow"
    actions = [
      "ecs:ListClusters",
      "ecs:DescribeClusters",
      "ecs:ListServices",
      "ecs:DescribeServices",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "tag:GetResources"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "prometheus_discovery" {
  name   = "${var.name_prefix}-prometheus-ecs-discovery"
  policy = data.aws_iam_policy_document.prometheus_discovery.json
}

resource "aws_iam_role_policy_attachment" "prometheus_attach" {
  role      = aws_iam_role.prometheus_task.name
  policy_arn = aws_iam_policy.prometheus_discovery.arn
}

# Loki task role (S3 access)
resource "aws_iam_role" "loki_task" {
  name               = "${var.name_prefix}-loki-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "loki_s3" {
  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [var.loki_bucket_arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["${var.loki_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "loki_s3" {
  name   = "${var.name_prefix}-loki-s3"
  policy = data.aws_iam_policy_document.loki_s3.json
}

resource "aws_iam_role_policy_attachment" "loki_attach" {
  role      = aws_iam_role.loki_task.name
  policy_arn = aws_iam_policy.loki_s3.arn
}
