import { AsgLifescycleEvent } from '../aws/asg';
import * as sns from '../aws/sns';
import { SnsNotificationLambdaRecord } from '../aws/sns';
import { sleep } from '../common/utils';
import * as lifecycle from './lifecycle';

const RETRY_INTERVAL = 15000; // ms (1000ms = 1s)

export interface LifecycleExecutionResponse {
  event: any;
  result?: lifecycle.ResultReadOnly;
  error?: Error;
}

export const handleSnsMessage = async (msg: SnsNotificationLambdaRecord): Promise<LifecycleExecutionResponse> => {
  console.log(`sns message: ${JSON.stringify(msg)}`);
  const notification = msg.Sns;
  const event = JSON.parse(notification.Message) as AsgLifescycleEvent;
  const response = { event: event } as LifecycleExecutionResponse;

  try {
    let result = await lifecycle.completeLifecycleAction(event);
    if (result.retry) {
      console.log('pausing before resending event for retry');
      await sleep(RETRY_INTERVAL);
      await sns.resendNotification(notification);
    }
    response.result = result;
  } catch (e: any) {
    console.log(`ERROR HANDLING SNS MESSGAGE: ${e}\n${e.StackTrace}`);
    response.error = e;
  }

  return response;
};
