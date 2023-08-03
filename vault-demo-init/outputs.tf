output "vault_pub_address" {
  value = aws_instance.vault-server.public_ip
}

output "vault_priv_address" {
  value = aws_instance.vault-server.private_ip
}

output "vpc_id" {
  value = module.vault-demo-vpc.vpc_id
} 

output "private_subnet_id" {
  value = module.vault-demo-vpc.private_subnets[0]
}

output "public_subnet_id" {
  value = module.vault-demo-vpc.public_subnets[0]
}

output "vault_security_group" {
  value = module.vault-security-group.security_group_id
}

output "vault_pass" {
  value = random_string.vault_pass.result
}

output "vpc_cidr" {
  value = module.vault-demo-vpc.vpc_cidr_block
}