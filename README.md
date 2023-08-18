# Terraform Module: ECS Cluster

This Terraform module provides a comprehensive solution for creating and
managing an AWS Elastic Container Service (ECS) cluster. Key features include
support for self-hosted nodes, both spot and on-demand, with configurable
auto-scaling policies.  The module also supports log retention configuration,
instance customization, and monitoring through collected metrics. It leverages
the `cloudposse/label/null` module for consistent naming and tagging of
resources. Whether you need a simple ECS cluster or a complex, self-hosted
environment, this module offers flexibility and ease of use to meet your
container orchestration needs.

## Features

- **ECS Cluster Creation**: Provides ECS cluster with optional self-hosted nodes
  (spot and on-demand).
- **Auto-Scaling Configuration**: Supports auto-scaling with customizable count
  range.
- **Instance Configuration**: Allows configuration of instance sizes and user
  data scripts.
- **Capacity Providers**: Configures ECS capacity providers.

## Usage

Deploy it using the block below.

```hcl
module "ecs_cluster" {
  source  = "cruxstack/ecs-cluster/aws"
  version = "x.x.x"

  vpc_id         = "vpc-00000000000000"
  vpc_subnet_ids = ["subnet-33333333333333", "subnet-44444444444444444", "subnet-55555555555555555"]
}
```

## Inputs

In addition to the variables documented below, this module includes several
other optional variables (e.g., `name`, `tags`, etc.) provided by the
`cloudposse/label/null` module. Please refer to its [documentation](https://registry.terraform.io/modules/cloudposse/label/null/latest)
for more details on these variables.

| Name                        | Description                                                           | Type           | Default         | Required |
|-----------------------------|-----------------------------------------------------------------------|----------------|-----------------|:--------:|
| `self_hosted`               | Enable self-hosted nodes                                              | `bool`         | `false`         |    no    |
| `autoscale_count_range`     | Autoscale range for spot and on-demand (format "0-3")                 | `object`       | `{}`            |    no    |
| `instance_sizes`            | List of instance sizes for the cluster                                | `list(string)` | `["m5d.large"]` |    no    |
| `vpc_id`                    | ID of the VPC for the resources                                       | `string`       | n/a             |   yes    |
| `vpc_subnet_ids`            | IDs of the subnets in the VPC for the resources                       | `list(string)` | n/a             |   yes    |
| `vpc_security_groups`       | Additional security group IDs for the instances                       | `list(string)` | `[]`            |    no    |
| `log_retention`             | Log retention in days                                                 | `number`       | `30`            |    no    |
| `aws_account_id`            | AWS account ID                                                        | `string`       | `""`            |    no    |
| `aws_region_name`           | AWS region name                                                       | `string`       | `""`            |    no    |
| `aws_kv_namespace`          | AWS Key-Value namespace                                               | `string`       | `null`          |    no    |
| `instance_userdata_scripts` | Additional user data scripts for instances                            | `list(string)` | `[]`            |    no    |
| `collected_metrics`         | Configuration of the cluster and instance metrics collection settings | `object`       | `{}`            |    no    |
| `iam_policy_arns`           | IAM policy ARNs to attach                                             | `list(string)` | `[]`            |    no    |

### Outputs

| Name                  | Description                              |
|-----------------------|------------------------------------------|
| `security_group_id`   | Security group ID for the ECS cluster.   |
| `security_group_name` | Security group name for the ECS cluster. |

## Contributing

We welcome contributions to this project. For information on setting up a
development environment and how to make a contribution, see [CONTRIBUTING](./CONTRIBUTING.md)
documentation.
