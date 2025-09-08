# A serverless Valkey ElastiCache instance for CyHy-BOD reporting
# orchestration
resource "aws_elasticache_serverless_cache" "cyhy_bod_orch" {
  description = "A serverless Valkey ElastiCache cache for CyHy-BOD reporting orchestration."
  engine      = "valkey"
  name        = "cyhy-bod-orchestration"
  security_group_ids = [
    aws_security_group.cache.id,
  ]
  subnet_ids = [
    aws_subnet.bod_docker_subnet.id,
  ]
}
