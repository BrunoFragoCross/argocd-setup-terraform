output "public_ip" {
  description = "Output the public ip of the EC2 for Putty connection"
  value       = aws_instance.linux_server.public_ip
}