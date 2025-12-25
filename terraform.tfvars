vpc_id = "vpc-057a63ab36710c621"

# ALB needs public subnets (internet-facing)
public_subnets = [
  "subnet-000c4f09fd19947ca",
  "subnet-02bf3d817dfe863f8"
]

# Ideally these are private subnets. If you don't have private subnets yet,
# you can temporarily set them to the same subnets (NOT recommended for production).
private_subnets = [
  "subnet-000c4f09fd19947ca",
  "subnet-02bf3d817dfe863f8"
]

# Restrict to your IP/CIDR when possible. Temporary example:
allowed_cidr = "203.0.113.0/32"

# Leave empty if no ACM cert yet (we will use HTTP listener)
certificate_arn = ""