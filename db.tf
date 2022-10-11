locals {
  resource_name_prefix = var.project
}


# resource "aws_secretsmanager_secret" "mysql_secret" {
#   name = "${local.resource_name_prefix}-mysql-secret-${random_string.secret_id.result}"

#   tags = merge(
#     var.custom_tags,
#     {
#       Project = var.project
#       Name    = "rds-mysql"
#     }
#   )
# }

# resource "aws_secretsmanager_secret_version" "mysql_secret_version" {
#   secret_id     = aws_secretsmanager_secret.mysql_secret.id
#   secret_string = <<EOF
#    {
#     "username": "${module.aurora_mysql.cluster_master_username}",
#     "password": "${module.aurora_mysql.cluster_master_password}"
#    }
# EOF
# }


# resource "aws_iam_role" "mysql-jump-host-iam-role" {
#   name = "${local.resource_name_prefix}-jump-host-role"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": {
#   "Effect": "Allow",
#   "Principal": {"Service": "ec2.amazonaws.com"},
#   "Action": "sts:AssumeRole"
#   }
#   }
#   EOF
# }
# resource "aws_iam_role_policy_attachment" "mysql-jump-host-ssm-policy" {
#   role       = aws_iam_role.mysql-jump-host-iam-role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_role_policy_attachment" "jump-host-ssm" {
#   role       = aws_iam_role.mysql-jump-host-iam-role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }


# module "aurora_mysql" {
#   source = "../../"

#   name              = "${local.name}-mysql"
#   engine            = "aurora-mysql"
#   engine_mode       = "serverless"
#   storage_encrypted = true

#   vpc_id                = module.vpc.vpc_id
#   subnets               = module.vpc.database_subnets
#   create_security_group = true
#   allowed_cidr_blocks   = module.vpc.private_subnets_cidr_blocks

#   monitoring_interval = 60

#   apply_immediately   = true
#   skip_final_snapshot = true

#   db_parameter_group_name         = aws_db_parameter_group.appsync_mysql.id
#   db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.appsync_mysql.id
#   # enabled_cloudwatch_logs_exports = # NOT SUPPORTED

#   scaling_configuration = {
#     auto_pause               = true
#     min_capacity             = 2
#     max_capacity             = 16
#     seconds_until_auto_pause = 300
#     timeout_action           = "ForceApplyCapacityChange"
#   }
# }


# resource "aws_db_parameter_group" "appsync_mysql" {
#   name        = "appsync-aurora-db-mysql-parameter-group"
#   family      = "aurora-mysql5.7"
#   description = "appsync-aurora-db-mysql-parameter-group"
#   tags        = local.tags
# }

# resource "aws_rds_cluster_parameter_group" "appsync_mysql" {
#   name        = "appsync-aurora-mysql-cluster-parameter-group"
#   family      = "aurora-mysql5.7"
#   description = "appsync-aurora-mysql-cluster-parameter-group"
#   tags        = local.tags
# }

resource "aws_secretsmanager_secret" "db-pass" {
  name = "${local.resource_name_prefix}-mysql-secret-${random_string.secret_id.result}"
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.db-pass.id
  secret_string = jsonencode(
    {
      username = aws_rds_cluster.cluster.master_username
      password = aws_rds_cluster.cluster.master_password
      engine   = "mysql"
      host     = aws_rds_cluster.cluster.endpoint
    }
  )
}

resource "aws_rds_cluster" "cluster" {
  # db_cluster_identifier = "${local.resource_name_prefix}-db"
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
