terraform {
  required_version = ">= 1.11.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.3.0"
    }
  }
}
provider "azuread" {
  tenant_id = "YOUR_TENANT_ID"
}