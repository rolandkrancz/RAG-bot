variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-rag-bot"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "app_name" {
  description = "Name of the Container App"
  type        = string
  default     = "rag-bot-app"
}

variable "container_image" {
  description = "Fully qualified image reference (e.g., ghcr.io/org/rag-bot:latest)"
  type        = string
  default     = "docker.io/library/nginx:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8000
}

variable "registry_server" {
  description = "Optional OCI registry server (e.g., ghcr.io)"
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Username for the container registry"
  type        = string
  default     = ""
}

variable "registry_password" {
  description = "Password or token for the container registry"
  type        = string
  sensitive   = true
  default     = ""
}

variable "openai_api_key" {
  description = "Optional OpenAI API Key injected as a secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "environment_variables" {
  description = "Plain-text environment variables for the container"
  type        = map(string)
  default = {
    APP_ENV = "sandbox"
  }
}

variable "min_replicas" {
  description = "Minimum number of container replicas"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Sandbox"
    Project     = "RAG-Bot"
    ManagedBy   = "Terraform"
  }
}
