# Values displayed after terraform apply
# Also usable by other Terraform modules

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "App server security group ID"
  value       = aws_security_group.app_server.id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_eip.app_server.public_ip
}

output "ec2_public_dns" {
  description = "EC2 instance public DNS"
  value       = aws_instance.app_server.public_dns
}

output "app_url" {
  description = "Application URL"
  value       = "http://${aws_eip.app_server.public_ip}"
}

output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh -i devops-key.pem ec2-user@${aws_eip.app_server.public_ip}"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.app_storage.bucket
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}
