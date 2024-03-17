
variable "domain" {
  description = "Zitadel Domain"
  type        = string
  default     = "zitadel.javstudio.org"
}

variable "port" {
  description = "Zitadel Port"
  type        = string
  default     = "443"
}

variable "insecure" {
  description = "Inscure Connection"
  type        = string
  default     = "false"
}

variable "jwt_profile_file" {
  description = "Machine JSON Key"
  type        = string
  default     = "../service-user-jwt/client-key-file.json"
}

variable "org" {
  description = "Organizarion"
  type        = string
  default     = "HOMELAB"
}

variable "project" {
  description = "Project"
  type        = string
  default     = "Homelab"
}

variable "application" {
  description = "Application"
  type        = string
  default     = "Proxy"
}

variable "redirect_url" {
  description = "Redirect URL"
  type        = string
  default     = "https://oauth.javstudio.org/oauth2/callback"
}

variable "user_name" {
  description = "Username"
  type        = string
  default     = "admin"
}

variable "user_email" {
  description = "Email"
  type        = string
  default     = "admin@zitadel.com"
}

variable "user_password" {
  description = "Password"
  type        = string
  sensitive   = true
  default     = "RootPasswors1!"
}
