#!/bin/bash -e
# shellcheck disable=SC2034,SC2154

echo "ECS_CLUSTER=${ecs_cluster_name}" >> /etc/ecs/ecs.config
