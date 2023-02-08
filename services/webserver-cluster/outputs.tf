output "public_ip" {
    value       = aws_lb.servidor-de-juanjo.dns_name
    description = "Public IP for server"
}

output "sg_id" {
  value = aws_security_group.sg-lb-juanjo.id
}
