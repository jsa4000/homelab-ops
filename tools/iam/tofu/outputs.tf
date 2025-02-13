output "defaul_org_id" {
  value = data.zitadel_org.default.id
}

output "defaul_org_name" {
  value = data.zitadel_org.default.name
}

output "defaul_project_id" {
  value = zitadel_project.default.id
}

output "zitadel_application_id" {
  value = zitadel_application_oidc.default.id
}

output "zitadel_application_client_id" {
  value = zitadel_application_oidc.default.client_id
  sensitive = true
}

output "zitadel_application_client_secret" {
  value = zitadel_application_oidc.default.client_secret
  sensitive = true
}

output "user_id" {
  value = zitadel_human_user.default.id
}
