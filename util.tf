resource "random_string" "secret_id" {
  length  = 12
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "random_password" "db_master_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}
