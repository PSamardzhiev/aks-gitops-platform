terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "dev.terraform.tfstate"
    use_azuread_auth = true
  }
}
