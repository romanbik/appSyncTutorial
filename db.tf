locals {
  resource_name_prefix = var.project
}

resource "aws_secretsmanager_secret" "db-pass" {
  name = "${local.resource_name_prefix}-mysql-secret-${random_string.secret_id.result}"
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.db-pass.id
  secret_string = jsonencode(
    {
      username      = aws_rds_cluster.cluster.master_username
      password      = aws_rds_cluster.cluster.master_password
      engine        = "mysql"
      host          = aws_rds_cluster.cluster.endpoint
      database_name = "appsync"
    }
  )
}

resource "aws_rds_cluster" "cluster" {
  engine               = "aurora-mysql"
  engine_version       = "5.7.mysql_aurora.2.07.1"
  engine_mode          = "serverless"
  database_name        = "appsync"
  master_username      = "admin"
  master_password      = random_password.db_master_pass.result
  enable_http_endpoint = true
  skip_final_snapshot  = true
  scaling_configuration {
    min_capacity = 1
  }
  lifecycle {
    # RDS auto-upgrades the version
    # so this tells Terraform not to downgrade it the next apply
    ignore_changes = [
      engine_version,
    ]
  }
}


