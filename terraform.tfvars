aws_region = "ap-south-1"
name_prefix = "obs"

vpc_id = "vpc-057a63ab36710c621"

public_subnet_ids  = ["subnet-000c4f09fd19947ca", "subnet-02bf3d817dfe863f8"]
private_subnet_ids = ["subnet-000c4f09fd19947ca", "subnet-02bf3d817dfe863f8"]

grafana_ingress_cidrs = ["0.0.0.0/0"]

prometheus_discover_cluster_names = ["dev-cluster"]  # add more clusters later
loki_retention_days = 30
