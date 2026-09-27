output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.vm.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.vm.public_ip
}

output "security_group_id" {
  description = "ID of the security group attached to the instance"
  value       = aws_security_group.vm_sg.id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created for storage"
  value       = aws_s3_bucket.storage.bucket
}

output "cloudwatch_alarm_name" {
  description = "Name of the CPU CloudWatch alarm (if enabled)"
  value       = var.enable_cpu_alarm ? aws_cloudwatch_metric_alarm.cpu_high[0].alarm_name : null
}
