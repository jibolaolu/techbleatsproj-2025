resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

# Create an AWS ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "my-redis-cluster"
  description                = "Managed Redis Cluster for ECS"
  node_type                  = "cache.t3.micro" # Choose an appropriate instance type
  num_cache_clusters         = 2                # Two nodes for high availability
  automatic_failover_enabled = true             # Enable automatic failover
  parameter_group_name       = "default.redis7"
  multi_az_enabled           = true # Enable Multi-AZ
  security_group_ids         = [aws_security_group.redis_sg.id]
  subnet_group_name          = aws_elasticache_subnet_group.redis_subnet_group.name

  tags = {
    Name = "MyRedisReplicationGroup"
  }
}
