output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = { for az, s in aws_subnet.public : az => s.id }
}

output "private_subnet_ids" {
  value = { for az, s in aws_subnet.private : az => s.id }
}

output "database_subnet_ids" {
  value = { for az, s in aws_subnet.database : az => s.id }
}

output "nat_gateway_ids" {
  value = { for az, n in aws_nat_gateway.main : az => n.id }
}
