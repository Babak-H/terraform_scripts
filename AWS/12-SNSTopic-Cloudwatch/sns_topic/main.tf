terraform {
  required_version = ">= 1.1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_sns_topic" "sns_topic" {
  name              = var.topic_name
  kms_master_key_id = var.kms_key_alias
  tags              = var.tags
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.sns_topic.arn
  policy = module.iam_policy_merge_sns.merged_document
  depends_on = [ aws_sns_topic.sns_topic ]
}
