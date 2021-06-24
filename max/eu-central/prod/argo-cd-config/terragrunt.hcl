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
  source = "git::git@github.com:dubass83/learn-terraform-provision-aks-cluster.git//argo-cd-config?ref=v0.0.21"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "${dependency.aks.outputs.kubernetes_cluster_name}"
}

provider "k8s" {
  config_context = "${dependency.aks.outputs.kubernetes_cluster_name}"
}
EOF
}

dependency "aks" {
  config_path  = "../aks"
}
dependency "argo-cd"{
  config_path = "../argo-cd"
  skip_outputs = true 
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {

}
