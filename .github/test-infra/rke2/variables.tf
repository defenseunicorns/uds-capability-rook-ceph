variable "name" {
  description = "Name for cluster"
  type        = string
  default     = "uds-rook-ci"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to deploy into"
  default     = "vpc-014f40526bbb55f29"
}

variable "ami" {
  type        = string
  description = "AMI to use for deployment, must have RKE2 pre-installed"
  # https://github.com/defenseunicorns/uds-rke2-image-builder
  default = "ami-078414c5ca373a397"
}

variable "region" {
  type        = string
  description = "Region to use for deployment"
  default     = "us-west-2"
}

variable "controlplane_internal" {
  type        = bool
  description = "Make controlplane internal"
  default     = false # Default public for CI
}

variable "associate_public_ip_address" {
  type        = bool
  description = "Add public IPs for nodes"
  default     = true # Default public for CI
}

variable "permissions_boundary_name" {
  type        = string
  description = "Permissions boundary for IAM Role"
  default     = "uds_ci_base_policy"
}
