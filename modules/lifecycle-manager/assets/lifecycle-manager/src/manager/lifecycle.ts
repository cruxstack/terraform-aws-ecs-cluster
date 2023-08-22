import * as asg from '../aws/asg';
import { AsgLifescycleEvent } from '../aws/asg';
import * as errors from '../common/errors';
import * as hooks from './hooks';

export interface ResultReadOnly {
  readonly state: string;
  readonly retry: boolean;
  readonly completed: boolean;
  readonly failed: boolean;
}

// possible lifecycle process result
const COMPLETED: ResultReadOnly = { state: 'COMPLETED', retry: false, completed: true, failed: false };
const FAILED: ResultReadOnly = { state: 'ABANDON', retry: false, completed: true, failed: true };
const NOT_READY: ResultReadOnly = { state: 'NOT_READY', retry: true, completed: false, failed: false };
const TEST: ResultReadOnly = { state: 'TEST', retry: false, completed: false, failed: false };


export const completeLifecycleAction = async (event: AsgLifescycleEvent): Promise<ResultReadOnly> => {
  console.log(`lifescycle event: ${JSON.stringify(event)}`);
  let result: ResultReadOnly;

  try {
    if (event.Event === asg.ASG_LIFECYCLE_TEST_EVENT_NAME) {
      result = TEST;
    } else {
      await hooks.handleHook(event);
      result = COMPLETED;
    }
  } catch (e: any) {
    if (e instanceof errors.ResourceNotInDesiredStateError) {
      console.log(`${e.data.resourceId} - not ready to continue lifecycle: ${e.data.message}`);
      result = NOT_READY;
    } else if (e instanceof errors.ResourceNotFoundError) {
      console.log(`${e.data.resourceId} - not appliable for lifecycle action: ${e.data.message}`);
      result = COMPLETED; // need to complete even if not appliable
    } else {
      result = FAILED;
      throw e;
    }
  } finally {
    if (result.failed)
      await asg.signalAbandonLifecycle(event);
    else if (result.completed)
      await asg.signalContinueLifecycle(event);
  }

  return result;
};
