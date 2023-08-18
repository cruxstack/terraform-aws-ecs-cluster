locals {
  name = "tf-example-${random_string.example_random_suffix.result}"
  tags = { tf_module = "cruxstack/ecs-cluster/aws", tf_module_example = "complete" }
}

# ================================================================== example ===

module "ecs_cluster" {
  source = "../.."

  self_hosted    = true
  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.vpc_subnet_ids

  log_retention     = var.log_retention
  instance_sizes    = var.instance_sizes
  collected_metrics = var.collected_metrics

  context = module.example_label.context # not required
}

# ===================================================== supporting-resources ===

module "example_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name        = local.name
  environment = "use1" # us-east-1
  tags        = local.tags
}

resource "random_string" "example_random_suffix" {
  length  = 6
  special = false
  upper   = false
}
