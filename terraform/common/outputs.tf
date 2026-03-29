output "github_actions_identity_id" {
  description = "Machine identity ID for GitHub Actions"
  value       = infisical_identity.github_actions.id
}

output "github_actions_client_id" {
  description = "Universal Auth client ID for GitHub Actions"
  value       = infisical_identity_universal_auth.github_actions.client_id
}

output "github_actions_client_secret" {
  description = "Universal Auth client secret for GitHub Actions (set as GH secret)"
  value       = infisical_identity_universal_auth.github_actions.client_secret
  sensitive   = true
}
