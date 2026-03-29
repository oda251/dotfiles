output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = { for k, v in github_repository.this : k => v.html_url }
}
