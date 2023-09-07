vpc_id = "vpc-081f234e2c0733938" # VPC to deploy into
public_subnets = ["subnet-0db0b1f83617a3fd3", "subnet-084a5e689f6dc7145", "subnet-0624dbb7638f8fda5"] # Public Subnets in VPC to use for server node
private_subnets = ["subnet-0a1ce9afaecf1cf7c", "subnet-0952b9db827bd62a5", "subnet-07ffe847349aac9a6"] # Private Subnets in VPC to use for agent nodes
ami = "ami-025f702317121c63d" # Base AMI (Ubuntu recommended) with RKE2 pre-installed
iam_permissions_boundary = "" # Optional permissions boundary to attach to IAM roles
name = "rke2-dev" # Name to attach to all objects, recommended to add your unique username
