module "vpc" {
  source     = "../Modules/vpc_data"
  vpc_id     = var.vpc_id
  subnet_ids = distinct(concat(var.public_subnet_ids, var.private_subnet_ids))
}

module "cluster" {
  source      = "../Modules/obs_cluster"
  name_prefix = var.name_prefix
  vpc_id      = var.vpc_id
}

# Loki S3 bucket (central storage, 30 days lifecycle)
resource "aws_s3_bucket" "loki" {
  bucket = "${var.name_prefix}-loki-${replace(var.vpc_id, "vpc-", "")}-${var.aws_region}"
}

resource "aws_s3_bucket_public_access_block" "loki" {
  bucket                  = aws_s3_bucket.loki.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  bucket = aws_s3_bucket.loki.id
  rule {
    id     = "expire"
    status = "Enabled"
    expiration { days = var.loki_retention_days }
  }
}

# Grafana admin password (no hard-coded secrets)
resource "random_password" "grafana_admin" {
  length  = 28
  special = true
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  name = "${var.name_prefix}-grafana-admin-password"
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id     = aws_secretsmanager_secret.grafana_admin.id
  secret_string = random_password.grafana_admin.result
}

module "iam" {
  source                 = "../Modules/iam"
  name_prefix            = var.name_prefix
  aws_region             = var.aws_region
  loki_bucket_arn        = aws_s3_bucket.loki.arn
  grafana_admin_secret_arn = aws_secretsmanager_secret.grafana_admin.arn
}

module "loki" {
  source              = "../Modules/loki"
  name_prefix         = var.name_prefix
  aws_region          = var.aws_region
  vpc_id              = var.vpc_id
  vpc_cidr            = module.vpc.vpc_cidr
  private_subnet_ids  = var.private_subnet_ids

  cluster_arn         = module.cluster.cluster_arn
  cluster_name        = module.cluster.cluster_name
  namespace_id        = module.cluster.namespace_id

  execution_role_arn  = module.iam.ecs_execution_role_arn
  task_role_arn       = module.iam.loki_task_role_arn

  loki_bucket_name    = aws_s3_bucket.loki.bucket
  loki_retention_days = var.loki_retention_days
}

module "prometheus" {
  source                  = "../Modules/prometheus"
  name_prefix             = var.name_prefix
  aws_region              = var.aws_region
  vpc_id                  = var.vpc_id
  vpc_cidr                = module.vpc.vpc_cidr
  private_subnet_ids      = var.private_subnet_ids

  cluster_arn             = module.cluster.cluster_arn
  cluster_name            = module.cluster.cluster_name
  namespace_id            = module.cluster.namespace_id

  execution_role_arn      = module.iam.ecs_execution_role_arn
  task_role_arn           = module.iam.prometheus_task_role_arn

  discover_cluster_names  = var.prometheus_discover_cluster_names
  loki_internal_host      = module.loki.loki_internal_host
  loki_internal_port      = 3100
}

module "grafana" {
  source                 = "../Modules/grafana"
  name_prefix            = var.name_prefix
  aws_region             = var.aws_region
  vpc_id                 = var.vpc_id
  vpc_cidr               = module.vpc.vpc_cidr

  public_subnet_ids      = var.public_subnet_ids
  private_subnet_ids     = var.private_subnet_ids

  grafana_ingress_cidrs  = var.grafana_ingress_cidrs
  grafana_acm_cert_arn   = var.grafana_acm_cert_arn

  cluster_arn            = module.cluster.cluster_arn
  cluster_name           = module.cluster.cluster_name
  namespace_id           = module.cluster.namespace_id

  execution_role_arn     = module.iam.ecs_execution_role_arn
  task_role_arn          = module.iam.grafana_task_role_arn

  grafana_admin_secret_arn = aws_secretsmanager_secret.grafana_admin.arn

  prometheus_internal_url = module.prometheus.prometheus_internal_url
  loki_internal_url       = module.loki.loki_internal_url

  prometheus_sg_id       = module.prometheus.prometheus_sg_id
  loki_sg_id             = module.loki.loki_sg_id
}

# Allow Grafana -> Prometheus/Loki (least privilege)
resource "aws_security_group_rule" "grafana_to_prometheus" {
  type                     = "ingress"
  security_group_id        = module.prometheus.prometheus_sg_id
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
  source_security_group_id = module.grafana.grafana_task_sg_id
  description              = "Grafana -> Prometheus"
}

resource "aws_security_group_rule" "grafana_to_loki" {
  type                     = "ingress"
  security_group_id        = module.loki.loki_sg_id
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  source_security_group_id = module.grafana.grafana_task_sg_id
  description              = "Grafana -> Loki"
}
