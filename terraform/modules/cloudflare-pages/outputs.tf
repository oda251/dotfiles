output "name" {
  value = cloudflare_pages_project.this.name
}

output "subdomain" {
  value = "${cloudflare_pages_project.this.name}.pages.dev"
}
