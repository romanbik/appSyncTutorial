
resource "aws_iam_role" "appsync-role" {
  name = "${local.resource_name_prefix}-appsync-role-${random_string.secret_id.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# ================
# --- Policies ---
# ----------------

# Invoke Lambda policy

data "aws_iam_policy_document" "iam_invoke_rds_secret_manager_policy_document" {
  statement {
    sid = "1"

    actions = [
      "rds-data:ExecuteStatement"
    ]

    resources = [
      aws_rds_cluster.cluster.arn,
    ]
  }

  statement {
    sid = "2"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.db-pass.arn,
    ]
  }
}

resource "aws_iam_policy" "iam_invoke_rds_secret_manager_policy" {
  name   = "${var.prefix}_iam_invoke_rds_secret_manager_policy"
  policy = data.aws_iam_policy_document.iam_invoke_rds_secret_manager_policy_document.json
}

# ===================
# --- Attachments ---
# -------------------

# Attach Invoke Lambda policy to AppSync role.

resource "aws_iam_role_policy_attachment" "appsync_invoke_rds_secret_manager" {
  role       = aws_iam_role.appsync-role.name
  policy_arn = aws_iam_policy.iam_invoke_rds_secret_manager_policy.arn
}
