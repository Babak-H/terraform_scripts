module "iam_policy_merge_sns" {
    source = "***"
    source_documents = [
        data.aws_iam_policy_document.sns_default_policy.json,
        var.additional_policy
    ]
}