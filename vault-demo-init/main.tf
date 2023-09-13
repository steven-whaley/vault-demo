resource "random_string" "vault_pass" {
  length  = 12
  special = false
}

#Create VPC and subnets for EC2 instances
module "vault-demo-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "vault-demo-vpc"
  cidr = "10.1.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnets  = ["10.1.11.0/24", "10.1.12.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

}

#Create Security Group for Vault instance
module "vault-security-group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "vault-server-access"
  description = "Allow SSH and HTTP into Vault Server"
  vpc_id      = module.vault-demo-vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8200
      to_port     = 8200
      protocol    = "tcp"
      description = "Connect to Vault UI/API"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      rule        = "all-all"
      description = "Allow egress to everything within VPC"
      cidr_blocks = module.vault-demo-vpc.vpc_cidr_block
    }
  ]

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["ssh-tcp", "mysql-tcp", "https-443-tcp"]
}

# #Create Instance profile for vault server to provision AWS dynamic credentials
# resource "aws_iam_instance_profile" "vault_server_profile" {
#   name = "vault_server_profile"
#   role = aws_iam_role.vault_server_role.name
# }

# resource "aws_iam_role" "vault_server_role" {
#   name = "vault_server_role"
#   path = "/"

#   assume_role_policy = <<EOF
# {
#       "Version": "2012-10-17",
#       "Statement": [
#           {
#               "Effect": "Allow",
#               "Action": [
#                   "sts:AssumeRole"
#              ],
#              "Principal": {
#                   "Service": [
#                     "ec2.amazonaws.com"
#                   ]
#              }
#          }
#       ]
#   }
#   EOF

#   inline_policy {
#     name = "vault_server_policy"

#     policy = jsonencode({
#       "Version" : "2012-10-17",
#       "Statement" : [
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "iam:AttachUserPolicy",
#             "iam:CreateAccessKey",
#             "iam:CreateUser",
#             "iam:DeleteAccessKey",
#             "iam:DeleteUser",
#             "iam:DeleteUserPolicy",
#             "iam:DetachUserPolicy",
#             "iam:GetUser",
#             "iam:ListAccessKeys",
#             "iam:ListAttachedUserPolicies",
#             "iam:ListGroupsForUser",
#             "iam:ListUserPolicies",
#             "iam:PutUserPolicy",
#             "iam:AddUserToGroup",
#             "iam:RemoveUserFromGroup"
#           ],
#           "Resource" : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/vault-*"]
#         },
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "iam:GetInstanceProfile",
#             "iam:GetUser",
#             "iam:GetRole"
#           ],
#           "Resource" : "*"
#         },
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "s3:*",
#           ],
#           "Resource" : "arn:aws:s3:::*"
#         },
#         {
#           "Effect" : "Allow",
#           "Action" : [
#             "kms:Decrypt",
#             "kms:Encrypt",
#             "kms:DescribeKey",
#             "kms:GenerateDataKey"
#           ],
#           "Resource" : "*"
#         }
#       ]
#     })
#   }
# }


#Create Vault server EC2 instance with AWS Linux AMI
resource "aws_instance" "vault-server" {
  ami           = data.aws_ami.vault_ami.id
  instance_type = "t3.micro"

  key_name                    = var.aws_key_name
  monitoring                  = true
  subnet_id                   = module.vault-demo-vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [module.vault-security-group.security_group_id]
  user_data_base64            = base64encode(data.template_file.vault-init.rendered)
  iam_instance_profile        = aws_iam_instance_profile.vault_instance_profile.name

  tags = {
    Name = "vault-demo"
  }
}

# SE Demo Account Hoops to jump through to make AWS Auth work

locals {
  my_email = split("/", data.aws_caller_identity.current.arn)[2]
}

# EC2 IAM role for authenticating with Vault
resource "aws_iam_role" "vault_target_iam_role" {
  name               = "aws-ec2role-for-vault-authmethod"
  assume_role_policy = data.aws_iam_policy_document.client_policy.json
  managed_policy_arns = [data.aws_iam_policy.admin_access.arn]
}

resource "aws_iam_instance_profile" "vault_instance_profile" {
  name = "demo_profile"
  role = aws_iam_role.vault_target_iam_role.name
}