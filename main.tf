locals {
  name                = coalesce(module.this.name, var.name, "ecs-cluster")
  enabled             = module.this.enabled
  self_hosted_enabled = local.enabled && var.self_hosted

  cluster_node_types = toset(local.self_hosted_enabled ? ["spot", "ondemand"] : [])

  aws_account_id   = var.aws_account_id != "" ? var.aws_account_id : try(data.aws_caller_identity.current[0].account_id, "")
  aws_region_name  = var.aws_region_name != "" ? var.aws_region_name : try(data.aws_region.current[0].name, "")
  aws_kv_namespace = trim(coalesce(var.aws_kv_namespace, "ecs-cluster/${module.cluster_label.id}"), "/")
}

data "aws_caller_identity" "current" {
  count = local.enabled && var.aws_account_id == "" ? 1 : 0
}

data "aws_region" "current" {
  count = local.enabled && var.aws_region_name == "" ? 1 : 0
}

# ================================================================== cluster ===

module "cluster_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = local.name
  context = module.this.context
}

resource "aws_ecs_cluster" "this" {
  count = local.enabled ? 1 : 0

  name = module.cluster_label.id

  dynamic "setting" {
    for_each = var.collected_metrics.cluster.insights_enabled ? [true] : []

    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  tags = module.cluster_label.tags
}

# ==================================================================== nodes ===

module "cluster_node_label" {
  source   = "cloudposse/label/null"
  version  = "0.25.0"
  for_each = local.cluster_node_types

  attributes = [each.key]
  tags       = { ("${local.aws_kv_namespace}/node-type") : each.key }
  context    = module.cluster_label.context
}

resource "aws_autoscaling_group" "this" {
  for_each = local.cluster_node_types

  name                  = module.cluster_node_label[each.key].id
  vpc_zone_identifier   = var.vpc_subnet_ids
  max_instance_lifetime = 86400
  metrics_granularity   = var.collected_metrics.autoscaling_group.granularity
  enabled_metrics       = var.collected_metrics.autoscaling_group.metrics
  termination_policies  = ["OldestLaunchTemplate", "AllocationStrategy", "Default"]
  health_check_type     = "EC2"

  desired_capacity = split("-", var.autoscale_count_range[each.key])[0]
  min_size         = split("-", var.autoscale_count_range[each.key])[0]
  max_size         = split("-", var.autoscale_count_range[each.key])[1]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = each.key == "ondemand" ? 100 : 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this[0].id
        version            = aws_launch_template.this[0].latest_version
      }

      dynamic "override" {
        for_each = var.instance_sizes

        content {
          instance_type     = override.value
          weighted_capacity = "1"
        }
      }
    }
  }

  instance_refresh {
    strategy = "Rolling"
    triggers = ["tag"]

    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(module.cluster_node_label[each.key].tags, { Name = module.cluster_node_label[each.key].id })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# ---------------------------------------------------------- launch-template ---

data "template_cloudinit_config" "this" {
  count = local.self_hosted_enabled ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-boothook"
    content      = file("${path.module}/assets/cloud-init/cloud_boothook.sh")
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/assets/cloud-init/cloud-config.yaml", {
      cluster_name = module.cluster_label.id
      cloudwatch_agent_config_encoded = base64encode(
        templatefile("${path.module}/assets/cloud-init/cloudwatch-agent-config.json", {
          cluster_log_group_name = aws_cloudwatch_log_group.this[0].name
        })
      )
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/assets/cloud-init/start_core_services.sh")
  }

  dynamic "part" {
    for_each = var.instance_userdata_scripts

    content {
      content_type = "text/x-shellscript"
      content      = part.value
    }
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/assets/cloud-init/userdata.sh", {
      ecs_cluster_name = module.cluster_label.id
      aws_account_id   = local.aws_account_id
      aws_region_name  = local.aws_region_name
      aws_kv_namespace = local.aws_kv_namespace
    })
  }
}

resource "aws_launch_template" "this" {
  count = local.self_hosted_enabled ? 1 : 0

  name                   = module.cluster_label.id
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami_id.value
  user_data              = data.template_cloudinit_config.this[0].rendered
  update_default_version = true

  iam_instance_profile {
    name = resource.aws_iam_instance_profile.this[0].id
  }

  monitoring {
    enabled = var.collected_metrics.instance.detailed_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 2
    http_tokens                 = "required"
    instance_metadata_tags      = "enabled"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = distinct(concat([module.security_group.id], var.vpc_security_groups))
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count = local.enabled ? 1 : 0

  name              = module.cluster_label.id
  retention_in_days = var.log_retention

  tags = module.cluster_label.tags
}

# ----------------------------------------------------------- security-group ---

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  enabled                    = local.self_hosted_enabled
  vpc_id                     = var.vpc_id
  create_before_destroy      = false
  preserve_security_group_id = true
  allow_all_egress           = true

  rules = [
    {
      key                      = "group-ingress"
      type                     = "ingress"
      from_port                = 8192
      to_port                  = 65535
      protocol                 = "tcp"
      description              = "allow traffic within group"
      cidr_blocks              = []
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = true
    },
  ]

  tags    = merge(module.cluster_label.tags, { Name = module.cluster_label.id })
  context = module.cluster_label.context
}

# ---------------------------------------------------------------------- iam ---

resource "aws_iam_instance_profile" "this" {
  count = local.enabled ? 1 : 0

  name = module.cluster_label.id
  role = aws_iam_role.this[0].name
}

resource "aws_iam_role" "this" {
  count = local.enabled ? 1 : 0

  name                 = module.cluster_label.id
  description          = ""
  assume_role_policy   = data.aws_iam_policy_document.ec2_assume_role.json
  max_session_duration = "3600"

  managed_policy_arns = distinct(concat([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ], var.iam_policy_arns))

  inline_policy {
    name   = "instance-access"
    policy = data.aws_iam_policy_document.cluster_instance_access.json
  }

  tags = module.cluster_label.tags
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    sid    = "AllowEc2Service"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession",
    ]
  }
}

data "aws_iam_policy_document" "cluster_instance_access" {
  statement {
    sid    = "AllowEcsClusterAccess"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:DescribeInstance*",
      "ec2:DescribeTags",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:Describe*",
      "ecs:DiscoverPollEndpoint",
      "ecs:List*",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:TagResource",
    ]

    resources = [
      "*"
    ]
  }
}

# ======================================================= capacity-providers ===

module "capacity_provider_label" {
  source   = "cloudposse/label/null"
  version  = "0.25.0"
  for_each = local.cluster_node_types

  delimiter      = "_"
  label_order    = ["name", "attributes"]
  label_key_case = "upper"

  context = module.cluster_node_label[each.key].context
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count = local.self_hosted_enabled ? 1 : 0

  cluster_name       = aws_ecs_cluster.this[0].name
  capacity_providers = concat(["FARGATE", "FARGATE_SPOT"], [for x in aws_ecs_capacity_provider.this : x.name])

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_capacity_provider" "this" {
  for_each = local.cluster_node_types

  name = replace(upper(module.capacity_provider_label[each.key].id), "-", "_")

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.this[each.key].arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 100
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

# ================================================================== lookups ===

data "aws_ssm_parameter" "ecs_optimized_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}
