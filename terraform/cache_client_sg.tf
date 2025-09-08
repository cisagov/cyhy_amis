# A security group for cache clients
resource "aws_security_group" "cache_client" {
  description = "Allow egress to the cache security group"
  name        = "cache_client"
  tags = {
    Name = "Cache client"
  }
  vpc_id = aws_vpc.bod_vpc.id
}

# Allow egress via port 6379 to the cache
resource "aws_security_group_rule" "egress_to_cache" {
  from_port                = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cache_client.id
  source_security_group_id = aws_security_group.cache.id
  to_port                  = 6379
  type                     = "egress"
}
