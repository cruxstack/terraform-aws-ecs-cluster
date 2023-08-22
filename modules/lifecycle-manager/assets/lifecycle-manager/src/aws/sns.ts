import * as AWS from 'aws-sdk';

export interface SnsNotificationLambdaRecord {
  EventSource: 'aws:sns';
  EventSubscriptionArn: string;
  EventVersion: string;
  Sns: SnsNotification;
  Subject: string;
  Type: 'Notification';
  UnsubscribeUrl: string;
}

export interface SnsNotification {
  SignatureVersion: string;
  Timestamp: string;
  Signature: string;
  SigningCertUrl: string;
  MessageId: string;
  Message: string;
  MessageAttributes: { [key: string]: any };
  Type: string;
  UnsubscribeUrl: string;
  TopicArn: string;
  Subject: string;
}

export const resendNotification = async (notification: SnsNotification) => {
  console.log(`resending sns notification: ${JSON.stringify(notification)}`);
  const sns = new AWS.SNS();
  let param = {
    Message: notification.Message,
    MessageAttributes: notification.MessageAttributes,
    Subject: notification.Subject,
    TopicArn: notification.TopicArn,
  };
  await sns.publish(param).promise();
};
