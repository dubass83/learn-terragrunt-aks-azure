# Set account-wide variables. These are automatically pulled in to configure the remote state bucket in the root
# terragrunt.hcl configuration.
locals {
  account_name = "max"
  // aws_account_id = "replaceme" # TODO: replace me with your AWS account ID!
  aws_profile = "s3-terraform-state"
}
