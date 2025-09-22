# Outputs for CI/CD Dashboard Infrastructure
# Generated with AI assistance (Cursor)

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.dashboard_sg.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.dashboard.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.dashboard.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.dashboard.public_dns
}

output "dashboard_frontend_url" {
  description = "URL to access the dashboard frontend"
  value       = "http://${aws_instance.dashboard.public_dns}:8080"
}

output "dashboard_api_url" {
  description = "URL to access the dashboard API"
  value       = "http://${aws_instance.dashboard.public_dns}:4000"
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.project_name}-key.pem ec2-user@${aws_instance.dashboard.public_dns}"
}

# Output for easy copy-paste testing
output "quick_test_urls" {
  description = "Quick test URLs for the deployed application"
  value = {
    frontend    = "http://${aws_instance.dashboard.public_ip}:8080"
    api_health  = "http://${aws_instance.dashboard.public_ip}:4000/api/health"
    api_metrics = "http://${aws_instance.dashboard.public_ip}:4000/api/metrics/summary"
  }
}
