import { SnsNotificationLambdaRecord } from './aws/sns';
import * as lifecycleHandlers from './manager/handlers';
import { LifecycleExecutionResponse } from './manager/handlers';

export interface LambdaTriggerEvent {
  Records: SnsNotificationLambdaRecord[];
}

export interface LambdaTriggerResponse {
  data: LifecycleExecutionResponse[];
  error?: Error;
}

export const handler = async (event: LambdaTriggerEvent): Promise<LambdaTriggerResponse> => {
  console.log(`lambda trigger event: ${JSON.stringify(event)}`);
  let response: LambdaTriggerResponse = { data: [] };

  try {
    const records = event.Records;
    for (let record of records) {
      let data = await lifecycleHandlers.handleSnsMessage(record);
      response.data.push(data);
    }
  } catch (e: any) {
    console.log(`CRITICAL ERROR: ${e}\n${e.StackTrace}`);
    response.error = JSON.parse(JSON.stringify(e, Object.getOwnPropertyNames(e)));
  }

  return response;
};
