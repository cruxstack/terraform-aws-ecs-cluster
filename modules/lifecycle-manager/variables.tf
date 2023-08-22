variable "asg_names" {
  type        = list(string)
  description = "List of ASG names to attach lifecycle hooks to."
  default     = []
}

variable "asg_lifecycle_hook_name" {
  type        = string
  description = "Name of the ASG lifecycle hook."
  default     = "ECS_CONTAINER_INSTANCE_TERMINATING"
}

variable "tag_name_ecs_cluster_name" {
  type        = string
  description = "Name of tag on EC2 instances that stores the ECS cluster name which instance belongs."
  default     = "ecs_cluster_name"
}
