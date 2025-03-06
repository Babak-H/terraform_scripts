data "aws_iam_policy_document" "sns_default_policy" {
    policy_id = "DefaultPolicy"
    statement {
        actions = [
            "SNS:GetTopicAttributes",
            "SNS:SetTopicAttributes",
            "SNS:AddPermission",
            "SNS:RemovePermission",
            "SNS:DeleteTopic",
            "SNS:Subscribe",
            "SNS:ListSubscriptionsByTopic",
            "SNS:Publish",
            "SNS:Receive"
        ]

        resources = [aws_sns_topic.sns_topic.arn]

        effect = "Allow"

        principals {
            type = "AWS"
            identifiers = ["*"]
        }

        sid = "DefaultPolicy"

        condition {
            test = "StringEquals"
            variable = "AWS:SourceOwner"
            values = var.allowed_accounts
        }
    }
}

data "aws_caller_identity" "current" {}