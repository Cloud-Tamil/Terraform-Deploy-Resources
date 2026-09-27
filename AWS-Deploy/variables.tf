# ==============================================================================
# Input Variables
# ==============================================================================

variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for naming resources (must be lowercase alphanumeric - S3 bucket names cannot contain uppercase)"
  type        = string
  default     = "cloudtamil-demo"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Base CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (spread across AZs)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (spread across AZs)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance size (t3.micro or t2.micro for AWS Free Tier eligibility)"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional EC2 SSH Key Pair name (leave null to use AWS SSM Session Manager instead)"
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "Allowed CIDR block for SSH access (e.g., your public IP like 203.0.113.5/32, or 0.0.0.0/0 for testing)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "enable_ecs_sample_service" {
  description = "Whether to spin up a sample lightweight Fargate container service in the ECS cluster"
  type        = bool
  default     = true
}