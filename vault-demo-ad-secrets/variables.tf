variable "region" {
  type        = string
  description = "The region to create instrastructure in"
  default     = "us-west-2"
}

variable "aws_key_name" {
  type        = string
  description = "The name of the key pair to associate with the EC2 instance"
  default     = "sw-ec2key"
}

variable "admin_pass" {
  type        = string
  description = "The default administrator password to set on the windows instances"
}