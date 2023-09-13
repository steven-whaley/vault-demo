# Create AWS Auth Backend and configure
resource "vault_auth_backend" "aws" {
  type = "aws"
}

resource "vault_aws_auth_backend_role" "vault_auth" {
  backend                  = vault_auth_backend.aws.path
  role                     = "vault_auth_role"
  auth_type                = "iam"
  bound_account_ids        = [data.aws_caller_identity.current.account_id]
  bound_iam_principal_arns = [data.tfe_outputs.vault_demo_init.values.vault_auth_role]
  token_ttl                = 60
  token_max_ttl            = 120
  token_policies           = ["aws"]
}

# Create AWS secrets engine
resource "vault_aws_secret_backend" "aws" {
  region = var.region
  default_lease_ttl_seconds = 180
  username_template = "{{ if (eq .Type \"STS\") }}{{ printf \"demo-steven.whaley@hashicorp.com-%s-%s\" (random 20) (unix_time) | truncate 32 }}{{ else }}{{ printf \"demo-steven.whaley@hashicorp.com-vault-%s-%s\" (unix_time) (random 20) | truncate 60 }}{{ end }}"
}

resource "vault_aws_secret_backend_role" "vault_role_iam_user_credential_type" {
  backend                  = vault_aws_secret_backend.aws.path
  credential_type          = "iam_user"
  name                     = "vault-demo-iam-user"
  permissions_boundary_arn = data.aws_iam_policy.demo_user_permissions_boundary.arn
  policy_document          = data.aws_iam_policy_document.vault_dynamic_iam_user_policy.json
}

resource "vault_aws_secret_backend_role" "vault_role_assumed_role_credential_type" {
  backend         = vault_aws_secret_backend.aws.path
  credential_type = "assumed_role"
  name            = "vault-demo-assumed-role"
  role_arns       = [data.aws_iam_role.vault_target_iam_role.arn]
}

# Create Policy for Vault server to read AWS secrets
resource "vault_policy" "aws" {
  name   = "aws"
  policy = <<EOT
    path "aws/creds/vault-demo-assumed-role"
    {
        capabilities = ["read"]
    }
    path "aws/creds/vault-demo-iam-user"
    {
        capabilities = ["read"]
    }
    EOT
}