locals {
  # Automatically load environment-level variables
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))

  # Extract out common variables for reuse
  env            = local.environment_vars.locals.environment
  azure_location = local.region_vars.locals.azure_location
}

# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "git::git@github.com:dubass83/learn-terraform-provision-aks-cluster.git//aks-login?ref=v0.0.8"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}


dependency "aks" {
  config_path  = "../aks"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  azurerm_resource_group      = dependency.aks.outputs.resource_group_name
  azurerm_kubernetes_cluster  = dependency.aks.outputs.kubernetes_cluster_name
}
