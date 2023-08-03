output "dc_priv_ip" {
    value = aws_instance.domain_controller.private_ip
}

output "dc_pub_ip" {
    value = aws_instance.domain_controller.public_ip
}