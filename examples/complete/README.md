# Example: Complete

This example demonstrates a complete deployment of the ECS Cluster module,
featuring a self-hosted ECS cluster with configurable instance sizes, log
retention, and metrics collection. The example showcases how to integrate the
module into your existing VPC and subnets, providing a tailored ECS cluster
deployment.

Usage

## Usage

To run this example, provide your own values for the following variables in a
`.terraform.tfvars` file:

```hcl
vpc_id         = "your-vpc-id"
vpc_subnet_ids = ["your-private-subnet-id"]
```

## Inputs


| Name                | Description                                                            | Type           | Default                                            | Required |
|---------------------|------------------------------------------------------------------------|----------------|----------------------------------------------------|:--------:|
| `instance_sizes`    | List of instance sizes (aka types) for the cluster.                    | `list(string)` | `["t3.nano", "t3.micro", "t3a.nano", "t3a.micro"]` |    no    |
| `log_retention`     | Number of days to retain logs.                                         | `number`       | `7`                                                |    no    |
| `collected_metrics` | Configuration of the cluster and instance metrics collection settings. | `object`       | `{}`                                               |    no    |
| `vpc_id`            | ID of the VPC for the resources.                                       | `string`       | n/a                                                |   yes    |
| `vpc_subnet_ids`    | IDs of the subnets in the VPC for the resources.                       | `list(string)` | n/a                                                |   yes    |

## Outputs

_This example does not define any specific outputs at this time._

