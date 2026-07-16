variable "subscription_id" {
  description = "Target Azure subscription ID. Terraform authenticates via your `az login` (Owner) identity."
  type        = string
  default     = "00000000-0000-0000-0000-000000000000"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "deployer_object_id" {
  description = <<-EOT
    Object ID of the human/identity running Terraform. Granted the Key Vault
    Secrets Officer RBAC role so it can seed the demo secret (RBAC vault has no
    access policies). Defaults to James.
  EOT
  type        = string
  default     = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
}

variable "enable_private_endpoint" {
  description = <<-EOT
    false (default) = FREE posture: Key Vault reached over a (free) service
    endpoint from the app subnet, RBAC-gated. true = add a Private Endpoint +
    Private DNS zone and disable public network access (~$7/mo while it exists;
    build it for the demo, then `terraform destroy`).
  EOT
  type        = bool
  default     = false
}

variable "restrict_network" {
  description = <<-EOT
    When true, Key Vault denies all networks except the app subnet (service
    endpoint) and `deployer_ip`. Keep false for the first apply so the demo
    secret can be seeded, then flip true to lock the public endpoint down.
    Ignored when enable_private_endpoint = true (public access is off entirely).
  EOT
  type        = bool
  default     = false
}

variable "deployer_ip" {
  description = "Your current public IP (CIDR or single IP) to allow when restrict_network = true. Leave empty to rely only on the subnet rule."
  type        = string
  default     = ""
}
