interface CustomErrorData {
  message: string;
  [key: string]: any;
}

interface CustomResourceErrorData extends CustomErrorData {
  message: string;
  resourceId: string;
}

export class CustomError extends Error {
  data: CustomErrorData;

  constructor(message: string) {
    super(message);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, CustomError);
    }
    this.data = { message: message };
  }
}

export class CustomResourceError extends CustomError {
  data: CustomResourceErrorData;

  constructor(message: string, resourceId: string) {
    super(message);
    this.data.resourceId = resourceId || 'unknown';
  }
}

export class ResourceNotFoundError extends CustomResourceError { }

export class ResourceNotAppliableError extends CustomResourceError { }

export class ResourceNotInDesiredStateError extends CustomResourceError { }
