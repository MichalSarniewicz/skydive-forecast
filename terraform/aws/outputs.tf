output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "ecr_gateway_url" {
  description = "ECR Gateway repository URL"
  value       = aws_ecr_repository.gateway.repository_url
}

output "ecr_user_service_url" {
  description = "ECR User Service repository URL"
  value       = aws_ecr_repository.user_service.repository_url
}

output "ecr_analysis_service_url" {
  description = "ECR Analysis Service repository URL"
  value       = aws_ecr_repository.analysis_service.repository_url
}

output "ecr_location_service_url" {
  description = "ECR Location Service repository URL"
  value       = aws_ecr_repository.location_service.repository_url
}

output "rds_user_endpoint" {
  description = "User DB endpoint"
  value       = aws_db_instance.user.endpoint
}

output "rds_analysis_endpoint" {
  description = "Analysis DB endpoint"
  value       = aws_db_instance.analysis.endpoint
}

output "rds_location_endpoint" {
  description = "Location DB endpoint"
  value       = aws_db_instance.location.endpoint
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "kafka_bootstrap_brokers" {
  description = "Kafka bootstrap brokers"
  value       = aws_msk_cluster.kafka.bootstrap_brokers
}

output "ecr_config_server_url" {
  description = "ECR Config Server repository URL"
  value       = aws_ecr_repository.config_server.repository_url
}
