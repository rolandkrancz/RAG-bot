output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.rag_bot.name
}

output "container_app_url" {
  description = "URL of the deployed Container App"
  value       = "https://${azurerm_container_app.rag_bot.ingress[0].fqdn}"
}

output "container_app_fqdn" {
  description = "Fully qualified domain name of the Container App"
  value       = azurerm_container_app.rag_bot.ingress[0].fqdn
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.rag_bot.name
}
