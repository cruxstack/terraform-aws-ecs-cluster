# ============================================================== ecs-cluster ===

variable "self_hosted" {
  type        = bool
  description = "Toggle self-hosted cluster."
  default     = false
}

variable "autoscale_count_range" {
  type = object({
    spot     = optional(string, "0-3")
    ondemand = optional(string, "0-3")
  })
  description = "Autoscale range for spot and on-demand (format `\"0-3\"`)."
  default     = {}
}

# ----------------------------------------------------------------- instance ---

variable "instance_sizes" {
  type        = list(string)
  description = "List of instance sizes (aka types) for the cluster."
  default     = ["m5d.large", "m5ad.large"]
}

variable "instance_userdata_scripts" {
  type        = list(string)
  description = "List of user data scripts for the instances."
  default     = []
}

# ------------------------------------------------------------ observability ---

variable "log_retention" {
  type        = number
  description = "Number of days to retain logs."
  default     = 90
}

variable "collected_metrics" {
  type = object({
    cluster = optional(object({
      insights_enabled = optional(bool, true)
    }), {})
    instance = optional(object({
      detailed_monitoring = optional(bool, true)
    }), {})
    autoscaling_group = optional(object({
      granularity = optional(string, "1Minute")
      metrics = optional(list(string), [
        "GroupMinSize",
        "GroupMaxSize",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupPendingInstances",
        "GroupStandbyInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances",
        "GroupInServiceCapacity",
        "GroupPendingCapacity",
        "GroupStandbyCapacity",
        "GroupTerminatingCapacity",
        "GroupTotalCapacity",
      ])
    }), {})
  })
  description = "Configuration of the cluster and instance metrics collection settings."
  default     = {}
}

# ---------------------------------------------------------------------- iam ---

variable "iam_policy_arns" {
  description = "List of IAM policy ARNs to attach."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------ network ---

variable "vpc_id" {
  description = "ID of the VPC for the resources."
  type        = string
}

variable "vpc_subnet_ids" {
  description = "IDs of the subnets in the VPC for the resources."
  type        = list(string)
}

variable "vpc_security_groups" {
  description = "List of security groups to attach to resources."
  type        = list(string)
  default     = []
}

# ================================================================== context ===

variable "aws_region_name" {
  type        = string
  description = "The name of the AWS region."
  default     = ""
}

variable "aws_account_id" {
  type        = string
  description = "The ID of the AWS account."
  default     = ""
}

variable "aws_kv_namespace" {
  type        = string
  description = "The namespace or prefix for AWS SSM parameters and similar resources."
  default     = ""
}
