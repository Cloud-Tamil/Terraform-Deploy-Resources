# ==============================================================================
# Security Groups: Firewall Rules for EC2 & ECS Cluster
# ==============================================================================

# 1. Web / EC2 Security Group
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Security group for EC2 instance: HTTP (80) and SSH (22)"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP (80) from anywhere for web app demo
  ingress {
    description = "Allow inbound HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH (22) restricted to allowed CIDR
  ingress {
    description = "Allow SSH from trusted IP or range"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # Outbound All Traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-web-sg"
  }
}

# 2. ECS Cluster / Service Security Group
resource "aws_security_group" "cluster_sg" {
  name        = "${var.project_name}-cluster-sg"
  description = "Security group for ECS tasks/containers"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP (80) for Fargate container test service
  ingress {
    description = "Allow HTTP inbound from within VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound All Traffic (needed to pull images and push logs)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-cluster-sg"
  }
}