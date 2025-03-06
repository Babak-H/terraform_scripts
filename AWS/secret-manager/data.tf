data "aws_kms_key" "secret_key" {
    key_id = "alias/data-encryption/${upper(var.environment)-DAT-SYS}"
}

data "aws_lambda_function" "lambda_rotation_name" {
    count = var.postgres_password ? 1 : 0
    function_name = "${var.seal_id}-${var.deployment_id}-${lower(var.environment)}-secret-rotation-lambda"
}

data "aws_lambda_function" "force_rotation_name" {
  count = var.postgres_password ? 1 : 0
  function_name = "${var.seal_id}-${var.deployment_id}-${lower(var.environment)}-force-secret-rotation-lambda"
}

data "aws_lambda_invocation" "rotate-secret" {
    count = var.postgres_password && var.stage == "apply" ? 1 : 0
    depends_on = [aws_secretsmanager_secret_version.true_version]

    function_name = data.aws_lambda_function.force_rotation_name[count.index].function_name
    input = <<JSON
    {
        "SecretId":           "${aws_secretsmanager_secret.true_secret[count.index].id}",
        "Step": "rotate"
    }
    JSON
}

