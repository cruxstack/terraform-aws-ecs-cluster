# ============================================================== ecs-cluster ===

variable "instance_sizes" {
  type        = list(string)
  description = "List of instance sizes (aka types) for the cluster."
  default     = ["t3.nano", "t3.micro", "t3a.nano", "t3a.micro"]
}

# ------------------------------------------------------------ observability ---

variable "log_retention" {
  type        = number
  description = "Number of days to retain logs."
  default     = 7
}

variable "collected_metrics" {
  type = object({
    cluster = optional(object({
      insights_enabled = optional(bool, false)
    }), {})
    instance = optional(object({
      detailed_monitoring = optional(bool, false)
    }), {})
  })
  description = "Configuration of the cluster and instance metrics collection settings."
  default     = {}
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
