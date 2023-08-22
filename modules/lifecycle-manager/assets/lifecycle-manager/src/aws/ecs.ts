import * as AWS from 'aws-sdk';
import * as errors from '../common/errors';
import { isNullOrEmpty } from '../common/utils';


export const checkContainerInstanceIsDrained = async (ecsInstance: AWS.ECS.ContainerInstance) => {
  console.log(`${ecsInstance.ec2InstanceId} - checking if instance has running ecs tasks`);
  if (ecsInstance.status !== 'DRAINING')
    throw new errors.ResourceNotInDesiredStateError("not in 'DRAINING' status", ecsInstance.ec2InstanceId);
  if (ecsInstance.runningTasksCount > 0)
    throw new errors.ResourceNotInDesiredStateError('has running tasks', ecsInstance.ec2InstanceId);
};

export const drainContainerInstance = async (ecsCluster: string, ecsInstance: AWS.ECS.ContainerInstance) => {
  console.log(`${ecsInstance.ec2InstanceId} - setting instance to draining ecs container instance state`);
  const ecs = new AWS.ECS();
  const params = {
    containerInstances: [ecsInstance.containerInstanceArn],
    status: 'DRAINING',
    cluster: ecsCluster,
  };
  await ecs.updateContainerInstancesState(params).promise();
};

export const listContainerInstances = async (name: string) => {
  const ecs = new AWS.ECS();
  const params: AWS.ECS.ListContainerInstancesRequest = {
    cluster: name,
  };
  let response = await ecs.listContainerInstances(params).promise();
  return response.containerInstanceArns;
};

export const describeContainerInstances = async (ecsClusterName: string, ecsInstanceArns?: string[]) => {
  const ecs = new AWS.ECS();
  ecsInstanceArns = ecsInstanceArns || await listContainerInstances(ecsClusterName);
  const params = {
    cluster: ecsClusterName,
    containerInstances: ecsInstanceArns,
  };
  let response = await ecs.describeContainerInstances(params).promise();
  return response.containerInstances;
};

export const getClusterContainerInstance = async (ecsClusterName: string, ec2Instance: AWS.EC2.Instance) => {
  let instanceId = ec2Instance.InstanceId;
  let ecsInstances = await describeContainerInstances(ecsClusterName);
  let ecsInstance = ecsInstances.find(x => x.ec2InstanceId === instanceId);
  if (isNullOrEmpty(ecsInstance))
    throw new errors.ResourceNotFoundError(`not found in '${ecsClusterName}' ecs cluster`, ec2Instance.InstanceId);
  console.log(`${ec2Instance.InstanceId} - logging container instance arn: ${ecsInstance.containerInstanceArn}`);
  return ecsInstance;
};

export const describeContainerInstance = async (ecsClusterName: string, ecsInstanceArn: string) => {
  let results = await describeContainerInstances(ecsClusterName, [ecsInstanceArn]);
  let ecsInstance = results[0];
  return ecsInstance;
};
