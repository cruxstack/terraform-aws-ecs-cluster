import * as AWS from 'aws-sdk';
import * as errors from '../common/errors';
import { isNullOrEmpty } from '../common/utils';

const ECS_CLUSTER_TAG_NAME = process.env.ECS_CLUSTER_TAG_NAME || 'ecs_cluster_name';

export const EC2_INSTANCE_STATE_TERMINATED = 'terminated';

export const describeInstance = async (id: string): Promise<AWS.EC2.Instance> => {
  const ec2 = new AWS.EC2();
  const params = { InstanceIds: [id] };

  try {
    let response = await ec2.describeInstances(params).promise();
    let reservations = response.Reservations[0] || {};
    return reservations.Instances[0];
  } catch (e: any) {
    if (e.code === 'InvalidInstanceID.NotFound')
      throw new errors.ResourceNotFoundError('does not exists', id);
    else
      throw e;
  }
};

export const isInstanceTerminated = (instance: AWS.EC2.Instance): boolean => {
  return instance.State.Name === EC2_INSTANCE_STATE_TERMINATED;
};

export const findEcsClusterName = (instance: AWS.EC2.Instance): string => {
  let tag = instance.Tags.find(x => x.Key === ECS_CLUSTER_TAG_NAME);
  if (isNullOrEmpty(tag))
    throw new errors.ResourceNotFoundError(`'${ECS_CLUSTER_TAG_NAME}' tag is missing`, instance.InstanceId);
  return tag.Value;
};
