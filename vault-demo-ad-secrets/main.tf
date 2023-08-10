#Create Domain Controller
resource "aws_instance" "domain_controller" {
  ami           = data.aws_ami.windows.id
  instance_type = "t3.medium"

  key_name                    = var.aws_key_name
  monitoring                  = true
  subnet_id                   = data.tfe_outputs.vault_demo_init.values.public_subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.dc_security_group.security_group_id]
  user_data                   = templatefile("domain-controller_userdata.tftpl", { admin_pass = var.admin_pass })

  tags = {
    Name = "vault-demo-domain-controller"
  }
}

#Create Security Group for Domain Controller
module "dc_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "dc-security-group"
  description = "Allow SSH and HTTP into Vault Server"
  vpc_id      = data.tfe_outputs.vault_demo_init.values.vpc_id

  ingress_cidr_blocks = ["97.115.136.153/32"]
  ingress_rules       = ["rdp-tcp"]

  ingress_with_cidr_blocks = [
    {
      rule        = "all-all"
      description = "Allow ingress from everything in VPC"
      cidr_blocks = data.tfe_outputs.vault_demo_init.values.vpc_cidr
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["http-80-tcp", "https-443-tcp"]
}

resource "vault_ldap_secret_backend" "ad" {
  path         = "vault-lab-ad"
  binddn       = "Administrator@vault.lab"
  bindpass     = var.admin_pass
  url          = "ldaps://${aws_instance.domain_controller.private_ip}"
  insecure_tls = "true"
  userdn       = "CN=Users,DC=vault,DC=lab"
  schema       = "ad"
}

resource "vault_ldap_secret_backend_library_set" "dev" {
  mount                        = vault_ldap_secret_backend.ad.path
  name                         = "dev"
  service_account_names        = ["sa1@vault.lab", "sa2@vault.lab"]
  ttl                          = 3600
  disable_check_in_enforcement = false
  max_ttl                      = 7200
}

resource "vault_ldap_secret_backend_static_role" "role" {
  mount           = vault_ldap_secret_backend.ad.path
  username        = "legacy_admin@vault.lab"
  role_name       = "legacy_admin"
  rotation_period = "3600"
}

resource "vault_ldap_secret_backend_dynamic_role" "domain_admin" {
  mount             = vault_ldap_secret_backend.ad.path
  role_name         = "domain_admin"
  creation_ldif     = file("${path.module}/ldifs/admin_creation.ldif")
  deletion_ldif     = file("${path.module}/ldifs/admin_deletion.ldif")
  rollback_ldif     = file("${path.module}/ldifs/admin_deletion.ldif")
  username_template = "v_admin_{{unix_time}}"
  default_ttl       = "3600"
}

resource "vault_ldap_secret_backend_dynamic_role" "domain_user" {
  mount             = vault_ldap_secret_backend.ad.path
  role_name         = "domain_user"
  creation_ldif     = file("${path.module}/ldifs/user_creation.ldif")
  deletion_ldif     = file("${path.module}/ldifs/user_deletion.ldif")
  rollback_ldif     = file("${path.module}/ldifs/user_deletion.ldif")
  username_template = "v_user_{{unix_time}}"
  default_ttl       = "3600"
}