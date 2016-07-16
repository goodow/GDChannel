#import "GDCBusProvider.h"
#import "GDCMqttBus.h"
#import "GDCMessageImpl.h"

@implementation GDCBusProvider

static NSString *clientId;
static id <GDCBus> instance;

+ (id <GDCBus>)instance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      if (instance) {
        return;
      }
#ifdef DEBUG
      instance = [[GDCMqttBus alloc] initWithHost:@"iot.eclipse.org" port:1883 localBus:nil clientId:[GDCBusProvider clientId]];
#else
      instance = [[GDCNotificationBus alloc] init];
#endif
  });

  return instance;
}

+ (NSString *)clientId {
  if (!clientId) {
    clientId = UIDevice.currentDevice.identifierForVendor.UUIDString;
  }
  return clientId;
}

+ (void)setInstance:(id <GDCBus>)bus {
  if (instance) {
    NSLog(@"Error: bus is already set, ignore");
    return;
  }
  instance = bus;
}

+ (void)setClientId:(NSString *)newClientId {
  if (clientId) {
    NSLog(@"Error: clientId is already set, ignore");
    return;
  }
  clientId = newClientId;
}

+ (void)redirectTopic:(NSString *)from to:(NSString *)to {
  [instance subscribeLocal:from handler:^(id <GDCMessage> message) {
      GDCMessageImpl *msg = message;
      if (!msg.send) {
        [instance publishLocal:to payload:message.payload options:message.options];
        return;
      }
      [self send:message replaceTopicWith:to local:YES];
  }];
}

+ (void)send:(id <GDCMessage>)message replaceTopicWith:(NSString *)topic local:(BOOL)local {
  GDCMessageImpl *msg = message;
  GDCAsyncResultBlock replyHandler = nil;
  if (msg.replyTopic) {
    replyHandler = ^(id <GDCAsyncResult> asyncResult) {
        if (asyncResult.failed) {
          [message fail:asyncResult.cause];
          return;
        }
        [self send:asyncResult.result replaceTopicWith:msg.replyTopic local:msg.local];
    };
  }
  if (local) {
    [instance sendLocal:topic payload:message.payload options:message.options replyHandler:replyHandler];
  } else {
    [instance send:topic payload:message.payload options:message.options replyHandler:replyHandler];
  }
}
@end