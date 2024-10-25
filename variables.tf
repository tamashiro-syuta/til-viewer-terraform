variable "client_id_list" {
  description = "CLient ID list of id provider(deploy_actions)"
  type        = list(string)
}
variable "thumbprint_list" {
  description = "Thumbprint list of id provider(deploy_actions)"
  type        = list(string)
}
variable "github_token" {
  description = "GitHub token for the Lambda function"
  type        = string
}
