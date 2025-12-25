variable "region" {
  default = "ap-south-1"
}

variable "vpc_id" {
  default = "vpc-057a63ab36710c621"
}

variable "private_subnets" {
  default = [
    "subnet-000c4f09fd19947ca",
    "subnet-02bf3d817dfe863f8"
  ]
}
