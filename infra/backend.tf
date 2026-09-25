terraform {
  backend "azurerm" {
    key              = "inventrack.tfstate"
    use_azuread_auth = true
  }
}