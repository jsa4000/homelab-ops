
provider "zitadel" {
  domain           = var.domain
  insecure         = var.insecure
  port             = var.port
  token = var.jwt_profile_file
}

data "zitadel_orgs" "default" {
  name          = var.org
  name_method   = "TEXT_QUERY_METHOD_EQUALS_IGNORE_CASE"
}

data "zitadel_org" "default" {
  id       = tolist(data.zitadel_orgs.default.ids)[0]
}

resource "zitadel_human_user" "default" {
  # count = var.azurerm_create_resource_group == false ? 1 : 0 # Check use already exists idempontence, stateless
  org_id             = data.zitadel_org.default.id
  user_name          = var.user_name
  first_name         = var.user_name
  last_name          = var.user_name
  nick_name          = var.user_name
  display_name       = var.user_name
  preferred_language = "en"
  gender             = "GENDER_MALE"
  phone              = "+41799999999"
  is_phone_verified  = true
  email              = var.user_email
  is_email_verified  = true
  initial_password   = var.user_password
}

resource "zitadel_instance_member" "default" {
  user_id = zitadel_human_user.default.id
  roles   = ["IAM_OWNER"]
}

resource "zitadel_project" "default" {
  name                     = var.project
  org_id                   = data.zitadel_org.default.id
  project_role_assertion   = true
  project_role_check       = true
  has_project_check        = true
  private_labeling_setting = "PRIVATE_LABELING_SETTING_ENFORCE_PROJECT_RESOURCE_OWNER_POLICY"
}

resource "zitadel_application_oidc" "default" {
  project_id = zitadel_project.default.id
  org_id     = data.zitadel_org.default.id

  name                        = var.application
  redirect_uris               = [var.redirect_url]
  response_types              = ["OIDC_RESPONSE_TYPE_CODE"]
  grant_types                 = ["OIDC_GRANT_TYPE_AUTHORIZATION_CODE"]
  post_logout_redirect_uris   = [var.redirect_url]
  app_type                    = "OIDC_APP_TYPE_WEB"
  auth_method_type            = "OIDC_AUTH_METHOD_TYPE_BASIC"
  version                     = "OIDC_VERSION_1_0"
  clock_skew                  = "0s"
  dev_mode                    = false
  access_token_type           = "OIDC_TOKEN_TYPE_BEARER"
  access_token_role_assertion = true
  id_token_role_assertion     = true
  id_token_userinfo_assertion = true
  additional_origins          = []
}

resource "zitadel_project_role" "default" {
  org_id       = data.zitadel_org.default.id
  project_id   = zitadel_project.default.id

  role_key     = "admin"
  display_name = "Admin"
  group        = "admin"
}

resource "zitadel_user_grant" "default" {
  org_id     = data.zitadel_org.default.id
  project_id = zitadel_project.default.id

  user_id    = zitadel_human_user.default.id
  role_keys  = ["admin"]
}
