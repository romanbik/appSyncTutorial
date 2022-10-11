terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.30"
    }
  }
}

# Set the AWS credentials profile and region you want to publish to.
provider "aws" {
  region                   = var.region
  shared_config_files      = ["~/.aws/config"]
  shared_credentials_files = ["~/.aws/credentials"]
}


# --- AppSync Setup ---

# Create the AppSync GraphQL api.
resource "aws_appsync_graphql_api" "appsync" {
  name                = "${var.prefix}_appsync"
  schema              = file("schema.graphql")
  authentication_type = "API_KEY"
  depends_on          = [aws_rds_cluster.cluster]

  # log_config {
  #   cloudwatch_logs_role_arn = aws_iam_role.graph_log_role.arn
  #   field_log_level          = "ALL"
  #   exclude_verbose_content  = false
  # }
}

# Create the API key.
resource "aws_appsync_api_key" "appsync_api_key" {
  api_id = aws_appsync_graphql_api.appsync.id
}

# Create data source in appsync from rds.
# resource "aws_appsync_datasource" "project_datasource" {
#   name             = "${var.prefix}_project_datasource"
#   api_id           = aws_appsync_graphql_api.appsync.id
#   service_role_arn = aws_iam_role.appsync-role.arn
#   type             = "RELATIONAL_DATABASE"
#   # lambda_config {
#   #   function_arn = aws_lambda_function.listPeople_lambda.arn
#   # }
# }


resource "aws_appsync_datasource" "rds" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "rds"
  service_role_arn = aws_iam_role.appsync-role.arn
  type             = "RELATIONAL_DATABASE"
  relational_database_config {
    http_endpoint_config {
      db_cluster_identifier = aws_rds_cluster.cluster.arn
      aws_secret_store_arn  = aws_secretsmanager_secret.db-pass.arn
      database_name         = aws_rds_cluster.cluster.database_name
    }
  }
}



