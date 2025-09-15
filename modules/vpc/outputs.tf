output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "The IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "The IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_route_table_ids" {
  value = [aws_route_table.private.id]
}

output "s3_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}