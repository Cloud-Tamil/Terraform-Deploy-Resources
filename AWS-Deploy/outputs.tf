# ==============================================================================
# Outputs: Key Resource Identifiers and Helpful Test Commands
# ==============================================================================

output "vpc_id" {
  description = "Custom VPC ID"
  value       = aws_vpc.main.id
}

output "internet_gateway_id" {
  description = "Internet Gateway attached to the custom VPC"
  value       = aws_internet_gateway.gw.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table routing to the IGW"
  value       = aws_route_table.public.id
}

output "web_security_group_id" {
  description = "Security Group ID guarding the EC2 instance"
  value       = aws_security_group.web_sg.id
}

output "cluster_security_group_id" {
  description = "Security Group ID guarding the ECS cluster"
  value       = aws_security_group.cluster_sg.id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.web_server.id
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "ec2_web_test_url" {
  description = "URL to test the EC2 web server in your browser"
  value       = "http://${aws_instance.web_server.public_ip}"
}

output "s3_bucket_name" {
  description = "Name of the created S3 bucket (with force_destroy enabled)"
  value       = aws_s3_bucket.app_storage.bucket
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "iam_ec2_role_arn" {
  description = "ARN of the IAM role attached to EC2"
  value       = aws_iam_role.ec2_role.arn
}

output "quick_test_commands" {
  description = "Commands to quickly verify your deployed resources"
  value = {
    test_web_server  = "curl -I http://${aws_instance.web_server.public_ip}"
    test_s3_contents = "aws s3 ls s3://${aws_s3_bucket.app_storage.bucket}"
    connect_via_ssm  = "aws ssm start-session --target ${aws_instance.web_server.id}"
    destroy_stack    = "terraform destroy -auto-approve"
  }
}