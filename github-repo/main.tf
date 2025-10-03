provider "github" {
  owner = var.github_owner
}

resource "github_repository" "charley_tf_repo" {
  name        = var.repo_name
  description = var.repo_description
  visibility  = var.repo_visibility
  auto_init   = var.repo_readme
}