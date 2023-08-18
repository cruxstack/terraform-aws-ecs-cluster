# ================================================================ resources ===

output "security_group_id" {
  value       = module.security_group.id
  description = "Security group ID for the ECS cluster."
}

output "security_group_name" {
  value       = module.security_group.name
  description = "Security group name for the ECS cluster."
}
