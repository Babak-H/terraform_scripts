##############################################################################
# Create and connect secret to rotation lambda if postgres_password is true.
##############################################################################
resource "aws_secretsmanager_secret" "true_secret" {
  count = "${var.postgres_password ? 1 : 0}"
  name = "${var.seal_id}-${var.deployment_id}-${lower(var.environment)}-${var.secret_name}"
  description                = "${var.description}"
  kms_key_id                 = "${var.kms_key_id}"
  recovery_window_in_days    = "${var.recovery_window_in_days}"
  rotation_lambda_arn        = "${data.aws_lambda_function.lambda_rotation_name.arn}"
  rotation_rules {
    automatically_after_days = "${var.rotation_frequency}"
  }
  tags = "${var.tags}"
}

#########################################################
# Create and store secret if postgres_password is false.
#########################################################
resource "aws_secretsmanager_secret" "false_secret" {
  count = "${var.postgres_password ? 0 : 1}"
  name                       = "${var.secret_name}"
  description                = "${var.description}"
  kms_key_id                 = "${var.kms_key_id}"
  recovery_window_in_days    = "${var.recovery_window_in_days}"
  tags                       = "${var.tags}"
}

#############################
# Create True Secret Value 
#############################
resource "aws_secretsmanager_secret_version" "true_version" {
  count = var.postgres_password ? 1 : 0

  lifecycle {
    ignore_changes = [ 
        secret_string
     ]
  }

  secret_id = aws_secretsmanager_secret.true_secret[count.index].id 
  secret_string = var.secret_string
}

############################# 
# Create False Secret Value 
#############################
resource "aws_secretsmanager_secret_version" "false_version" {
  count         = var.postgres_password ? 0 : 1
  secret_id = aws_secretmanager_secret.false_secret[count.index].id
  secret_string = var.secret_string

  lifecycle {
    ignore_changes = [ 
        secret_string
     ]
  }
}