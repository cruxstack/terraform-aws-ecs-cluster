locals {
  enabled = module.this.enabled

  asg_hook_name    = var.asg_lifecycle_hook_name
  cluster_tag_name = var.tag_name_ecs_cluster_name
}

# ======================================================== lifecycle-manager ===

module "lifecycle_manager_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  attributes = ["lifecycle-manager"]
  context    = module.this.context
}

resource "aws_lambda_function" "this" {
  count = local.enabled ? 1 : 0

  function_name = module.lifecycle_manager_label.id
  filename      = module.lifecycle_manager_code.artifact_package_path
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 45
  role          = aws_iam_role.this[0].arn
  layers        = []

  environment {
    variables = {
      ASG_LIFECYCLE_ECS_TERMINATING_HOOK = local.asg_hook_name
      ECS_CLUSTER_TAG_NAME               = local.cluster_tag_name
    }
  }

  tags       = module.lifecycle_manager_label.tags
  depends_on = [module.lifecycle_manager_code]
}

module "lifecycle_manager_code" {
  source  = "cruxstack/artifact-packager/docker"
  version = "1.3.6"

  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/lifecycle-manager")
  docker_build_target    = "package"
  context                = module.lifecycle_manager_label.context
}

# ------------------------------------------------------------- subscription ---

resource "aws_sns_topic" "this" {
  count = local.enabled ? 1 : 0

  name = module.lifecycle_manager_label.id
  tags = module.lifecycle_manager_label.tags
}

resource "aws_sns_topic_subscription" "this" {
  count = local.enabled ? 1 : 0

  protocol  = "lambda"
  topic_arn = aws_sns_topic.this[0].arn
  endpoint  = aws_lambda_function.this[0].arn
}

resource "aws_lambda_permission" "this" {
  count = local.enabled ? 1 : 0

  statement_id  = "allow-sns-trigger"
  function_name = aws_lambda_function.this[0].function_name
  action        = "lambda:InvokeFunction"
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this[0].arn
}

# -------------------------------------------------------------------- hooks ---

resource "aws_autoscaling_lifecycle_hook" "this" {
  count = length(var.asg_names)

  name                    = "ECS_CONTAINER_INSTANCE_TERMINATING"
  autoscaling_group_name  = var.asg_names[count.index]
  default_result          = "CONTINUE"
  heartbeat_timeout       = 330
  lifecycle_transition    = "autoscaling:EC2_INSTANCE_TERMINATING"
  notification_target_arn = aws_sns_topic.this[0].arn
  role_arn                = aws_iam_role.this[0].arn
}

# ---------------------------------------------------------------------- iam ---

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name        = module.lifecycle_manager_label.id
  description = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { "Service" : ["lambda.amazonaws.com", "autoscaling.amazonaws.com"] }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name   = "access"
    policy = data.aws_iam_policy_document.this[0].json
  }

  tags = module.lifecycle_manager_label.tags
}

data "aws_iam_policy_document" "this" {
  count = local.enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.this[0].arn
    ]

  }
  statement {

    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "ec2:DescribeInstances",
      "ecs:ListContainerInstances",
      "ecs:DescribeContainerInstances",
      "ecs:UpdateContainerInstancesState",
    ]
    resources = [
      "*",
    ]

  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:ListServices",
      "ecs:UpdateService",
      "ecs:TagResource",
      "ecs:UntagResource",
    ]
    resources = [
      "*",
    ]
  }
}
