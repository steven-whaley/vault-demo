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

data "aws_region" "current" {}

data "aws_iam_policy" "demo_user_permissions_boundary" {
  name = "DemoUser"
}

data "aws_iam_policy" "admin_access" {
  name = "AdministratorAccess"
}

data "aws_iam_policy_document" "client_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}