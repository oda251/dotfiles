output "name" {
  description = "Cloudflare Pages project name"
  value       = cloudflare_pages_project.this.name
}

output "subdomain" {
  description = "Default Pages deployment subdomain"
  value       = "${cloudflare_pages_project.this.name}.pages.dev"
}
