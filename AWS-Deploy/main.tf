data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Amazon Linux 2023 AMI, so you don't have to hardcode an AMI ID per region
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = var.bucket_name != null ? var.bucket_name : "${var.project_name}-${random_id.suffix.hex}"

  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Security Group — only the rules actually needed: SSH in, all out
# ---------------------------------------------------------------------------
resource "aws_security_group" "vm_sg" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH inbound only; all outbound"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from allowed CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-sg" })
}

# ---------------------------------------------------------------------------
# EC2 instance — basic (free) monitoring only, no detailed monitoring
# ---------------------------------------------------------------------------
resource "aws_instance" "vm" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.vm_sg.id]

  # false = basic monitoring (5-min, free); true = detailed (1-min, paid)
  monitoring = false

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-vm" })
}

# ---------------------------------------------------------------------------
# S3 bucket — private, encrypted, versioned, no public access
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "storage" {
  bucket = local.bucket_name

  tags = merge(local.common_tags, { Name = local.bucket_name })
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "storage" {
  bucket = aws_s3_bucket.storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "storage" {
  bucket = aws_s3_bucket.storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------------------------------
# Monitoring — only what's necessary: one CPU alarm, using the free
# basic metrics EC2 already reports (no extra agents/log groups unless needed)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count = var.enable_cpu_alarm ? 1 : 0

  alarm_name          = "${var.project_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold
  alarm_description   = "Triggers when average CPU exceeds threshold for 10 minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.vm.id
  }

  tags = local.common_tags
}
