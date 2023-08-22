import { AsgLifescycleEvent } from '../aws/asg';
import * as ec2 from '../aws/ec2';
import * as ecs from '../aws/ecs';

// lifecycle hook names
const ASG_LIFECYCLE_ECS_TERMINATING_HOOK = process.env.ASG_LIFECYCLE_ECS_TERMINATING_HOOK || 'ECS_CONTAINER_INSTANCE_TERMINATING';

const stopEcsOperations = async (ec2Instance: AWS.EC2.Instance) => {
  if (ec2.isInstanceTerminated(ec2Instance))
    return; // do not continue if instance is terminated

  console.log(`${ec2Instance.InstanceId} - stopping ecs operations on instance`);
  let ecsClusterName = ec2.findEcsClusterName(ec2Instance);
  let ecsInstance = await ecs.getClusterContainerInstance(ecsClusterName, ec2Instance);

  if (ecsInstance?.status !== 'DRAINING')
    await ecs.drainContainerInstance(ecsClusterName, ecsInstance);
  await ecs.checkContainerInstanceIsDrained(ecsInstance);
  console.log(`${ec2Instance.InstanceId} - ecs operation on instance is stopped`);
};

export const handleHook = async (event: AsgLifescycleEvent) => {
  let hookName = event.LifecycleHookName;
  let ec2Instance = await ec2.describeInstance(event.EC2InstanceId);
  console.log(`${ec2Instance.InstanceId} - logging instance description: ${JSON.stringify(ec2Instance)}`);

  if (hookName === ASG_LIFECYCLE_ECS_TERMINATING_HOOK)
    await stopEcsOperations(ec2Instance);
};
