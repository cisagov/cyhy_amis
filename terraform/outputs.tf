output "cyhy_lambda_https_sg" {
  description = "The security group that allows HTTPS egress to anywhere for Lambda functions in the CyHy VPC."
  value       = aws_security_group.lambda_https_sg
}

output "cyhy_lambda_mongodb_sg" {
  description = "The security group that allows ingress to the CyHy MongoDB server for Lambda functions in the CyHy VPC."
  value       = aws_security_group.lambda_mongodb_sg
}

output "cyhy_private_sg" {
  description = "The security group for the private portion of the CyHy VPC."
  value       = aws_security_group.cyhy_private_sg
}

output "cyhy_private_subnet" {
  description = "The private subnet of the CyHy VPC."
  value       = aws_subnet.cyhy_private_subnet
}

output "cyhy_public_subnet" {
  description = "The public subnet of the CyHy VPC."
  value       = aws_subnet.cyhy_public_subnet
}

output "cyhy_vpc" {
  description = "The CyHy VPC."
  value       = aws_vpc.cyhy_vpc
}
