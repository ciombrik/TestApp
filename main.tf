terraform {
  backend "remote" {
    organization = "ACG-Terraform-Demos-Alex"

    workspaces {
      name = "gh-actions"
    }
  }
}