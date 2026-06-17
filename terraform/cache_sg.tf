# A security group for the cache itself
resource "aws_security_group" "cache" {
  description = "Allow ingress from the cache client security group"
  name        = "cache"
  tags = {
    Name = "Cache"
  }
  vpc_id = aws_vpc.bod_vpc.id
}

# Allow ingress via port 6379 from cache clients
resource "aws_security_group_rule" "ingress_from_cache_clients" {
  from_port                = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cache.id
  source_security_group_id = aws_security_group.cache_client.id
  to_port                  = 6379
  type                     = "ingress"
}

# Allow ingress via port 6379 from the CyHy private subnet, so those
# instances can access the cache.
resource "aws_security_group_rule" "ingress_from_cyhy_private_subnet" {
  cidr_blocks       = [aws_subnet.cyhy_private_subnet.cidr_block]
  from_port         = 6379
  protocol          = "tcp"
  security_group_id = aws_security_group.cache.id
  to_port           = 6379
  type              = "ingress"
}
