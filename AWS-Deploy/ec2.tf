# ==============================================================================
# AWS EC2 Instance: Amazon Linux 2023 with Live Status Web Server & IAM Profile
# ==============================================================================

# Automatically query latest Amazon Linux 2023 AMI for region
data "aws_ami" "amazon_linux_2023" {
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

# EC2 Virtual Machine
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Enforce IMDSv2
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Bootstrap script: starts a lightweight web server showing live AWS metadata
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd awscli

              systemctl start httpd
              systemctl enable httpd

              # Fetch EC2 metadata via IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
              LOCAL_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
              PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)

              cat <<HTML > /var/www/html/index.html
              <!DOCTYPE html>
              <html lang="en">
              <head>
                <meta charset="UTF-8">
                <title>Terraform AWS Deployment Success</title>
                <style>
                  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 40px; margin: 0; }
                  .card { background: #1e293b; border-radius: 12px; padding: 28px; max-width: 680px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
                  h1 { color: #38bdf8; margin-top: 0; font-size: 26px; }
                  .badge { background: #0284c7; color: #ffffff; padding: 4px 10px; border-radius: 20px; font-size: 13px; font-weight: bold; }
                  .grid { display: grid; grid-template-columns: 140px 1fr; gap: 12px; margin-top: 20px; font-size: 15px; }
                  .label { color: #94a3b8; font-weight: 600; }
                  .val { color: #e2e8f0; font-family: monospace; }
                  .note { margin-top: 24px; padding: 14px; background: #334155; border-radius: 8px; font-size: 14px; color: #cbd5e1; }
                </style>
              </head>
              <body>
                <div class="card">
                  <div style="display:flex; justify-content:space-between; align-items:center;">
                    <h1>Terraform AWS Stack Active</h1>
                    <span class="badge">Running</span>
                  </div>
                  <p>All core infrastructure components have been deployed cleanly via Terraform.</p>
                  <div class="grid">
                    <span class="label">Instance ID:</span><span class="val">$INSTANCE_ID</span>
                    <span class="label">Availability Zone:</span><span class="val">$AZ</span>
                    <span class="label">Public IP:</span><span class="val">$PUBLIC_IP</span>
                    <span class="label">Private IP:</span><span class="val">$LOCAL_IP</span>
                    <span class="label">VPC CIDR:</span><span class="val">${var.vpc_cidr}</span>
                    <span class="label">S3 Bucket:</span><span class="val">${aws_s3_bucket.app_storage.bucket}</span>
                  </div>
                  <div class="note">
                    <strong>Clean Teardown Reminder:</strong> When you are ready, run <code>terraform destroy</code>.
                  </div>
                </div>
              </body>
              </html>
              HTML
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-ec2-web"
  }
}