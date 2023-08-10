data "aws_caller_identity" "current" {}

data "aws_ami" "vault_ami" {
  most_recent = true
  owners      = [data.aws_caller_identity.current.account_id]

  filter {
    name   = "name"
    values = ["vault-*"]
  }
}

data "template_file" "vault-init" {
  template = file("${path.module}/vault_user_data.tftpl")
  vars = {
    vaultpass = random_string.vault_pass.result
  }
}