import * as AWS from 'aws-sdk';

export interface AsgLifescycleEvent {
  Service: 'AWS Auto Scaling';
  AccountId: string;
  AutoScalingGroupARN?: string;
  AutoScalingGroupName: string;
  EC2InstanceId?: string;
  Event?: 'autoscaling:TEST_NOTIFICATION';
  LifecycleActionToken: string;
  LifecycleHookName: string;
  LifecycleTransition: string;
  RequestId: string;
}

export type AsgLifecycleActionResult = 'CONTINUE' | 'ABANDON';

export const ASG_LIFECYCLE_TEST_EVENT_NAME = 'autoscaling:TEST_NOTIFICATION';

export const completeLifecycleAction = async (event: AsgLifescycleEvent, result: AsgLifecycleActionResult) => {
  console.log(`${event.EC2InstanceId} - sending '${result}' for lifecycle action for instance `);
  const asg = new AWS.AutoScaling();
  const lifecycleParams = {
    AutoScalingGroupName: event.AutoScalingGroupName,
    LifecycleActionResult: result,
    LifecycleHookName: event.LifecycleHookName,
    InstanceId: event.EC2InstanceId,
  };
  await asg.completeLifecycleAction(lifecycleParams).promise();
};

export const signalContinueLifecycle = async (event: AsgLifescycleEvent) => {
  await completeLifecycleAction(event, 'CONTINUE');
};

export const signalAbandonLifecycle = async (event: AsgLifescycleEvent) => {
  await completeLifecycleAction(event, 'ABANDON');
};
