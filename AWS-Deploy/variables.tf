variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag all resources"
  type        = string
  default     = "basic-vm-stack"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access (leave null to skip key-based SSH)"
  type        = string
  default     = null
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance (e.g. \"203.0.113.5/32\"). Do not leave as 0.0.0.0/0 in real use."
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 8
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name. If left null, a unique name is generated."
  type        = string
  default     = null
}

variable "enable_cpu_alarm" {
  description = "Whether to create a basic CloudWatch CPU utilization alarm"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU % threshold that triggers the alarm"
  type        = number
  default     = 80
}
