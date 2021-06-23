output "storage_account_web_url" {
  value = azurerm_storage_account.web.primary_web_endpoint
}

output "frontend_url" {
  value = "http://${local.web_hostname}"
}
