output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  value = aws_db_instance.main.address
}

output "db_instance_arn" {
  value = aws_db_instance.main.arn
}

output "db_master_user_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "security_group_id" {
  value = aws_security_group.rds.id
}
