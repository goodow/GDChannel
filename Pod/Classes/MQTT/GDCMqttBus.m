#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCMqttBus.h"
#import "MQTTKit.h"
#import "GDCNotificationBus.h"
#import "GDCTopicsManager.h"

@interface GDCMqttBus ()
@property(nonatomic, readonly, strong) GDCNotificationBus *localBus;
@property(nonatomic, readonly, strong) MQTTClient *mqtt;
@property(nonatomic, readonly, strong) dispatch_queue_t queue;
@end

@implementation GDCMqttBus

- (instancetype)initWithHost:(NSString *)host port:(int)port clientId:(NSString *)clientId {
  self = [super init];
  if (self) {
    _localBus = [[GDCNotificationBus alloc] init];
    _mqtt = [[MQTTClient alloc] initWithClientId:clientId];
    _mqtt.port = (unsigned short) port;
    _queue = dispatch_queue_create("com.goodow.realtime.channel.queue", DISPATCH_QUEUE_SERIAL);

    __weak GDCMqttBus *weakSelf = self;
    [_mqtt disconnectWithCompletionHandler:^(NSUInteger code) {
        NSLog(@"Warning: MQTT disconnected(%i)", (int) code);
        [weakSelf publishLocal:GDC_BUS_ON_CLOSE payload:@{@"code" : @(code)}];
    }];
    // define the handler that will be called when MQTT messages are received by the client
    [_mqtt setMessageHandler:^(MQTTMessage *message) {
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:message.payload
                                                  options:NSJSONReadingAllowFragments
                                                    error:&error];
        if (!json) {
          @throw [NSException exceptionWithName:@"JSON" reason:[NSString stringWithFormat:@"Can't parse JSON string: %@", error] userInfo:nil];
        }

        // the MQTTClientDelegate methods are called from a GCD queue.
        // Any update to the UI must be done on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
            msg.topic = message.topic;
            if (json[errorKey]) {
              NSDictionary *error2 = json[errorKey];
              msg.payload = [NSError errorWithDomain:error2[errorDomainKey] code:[error2[errorCodeKey] integerValue] userInfo:error2[errorUserInfoKey]];
            } else {
              msg.payload = json[payloadKey];
            }
            msg.local = [json[localKey] boolValue];
            msg.send = [json[sendKey] boolValue];
            msg.options = json[optionsKey];
            msg.replyTopic = json[replyTopicKey];
            if (msg.replyTopic && msg.send) {
              msg.bus = weakSelf;
            }
            [weakSelf.localBus sendOrPub:msg replyHandler:nil];
        });
    }];

    // connect the MQTT client
    dispatch_barrier_async(_queue, ^{
        [_mqtt connectToHost:host completionHandler:^(MQTTConnectionReturnCode code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (code == ConnectionAccepted) {
                  // The client is connected when this completion handler is called
                  NSLog(@"client is connected with id %@", clientId);
                  [weakSelf publishLocal:GDC_BUS_ON_OPEN payload:@{@"clientId" : clientId}];
                } else {
                  NSLog(@"Error: connection refused(%i)", (int) code);
                  [weakSelf publishLocal:GDC_BUS_ON_ERROR payload:@{@"code" : @(code)}];
                }
            });
        }];
    });
  }
  return self;
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton"
                                 reason:[NSString stringWithFormat:@"Use %@ %@", NSStringFromClass(GDCMqttBus.class), NSStringFromSelector(@selector(initWithHost:port:clientId:))]
                               userInfo:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload {
  return [self publish:topic payload:payload options:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload options:(NSDictionary *)options {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.options = options;
  [self sendOrPub:msg];
  return self;
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  return [self publishLocal:topic payload:payload options:nil];
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options {
  [self.localBus publishLocal:topic payload:payload options:options];
  return self;
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self send:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  NSString *replyTopic = nil;
  if (replyHandler) {
    replyTopic = [GDCMessageImpl generateReplyTopic:topic];
    __block id <GDCMessageConsumer> consumer = [self subscribe:replyTopic handler:^(id <GDCMessage> message) {
        [consumer unsubscribe];
        GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
        replyHandler(asyncResult);
    }];
  }

  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.replyTopic = replyTopic;
  msg.send = YES;
  msg.options = options;
  [self sendOrPub:msg];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self sendLocal:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  [self.localBus sendLocal:topic payload:payload options:options replyHandler:replyHandler];
  return self;
}

- (id <GDCMessageConsumer>)subscribe:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  __weak GDCMqttBus *weakSelf = self;
  int retainCount = [self.localBus.topicsManager retainCountOfTopic:topicFilter];
  id <GDCMessageConsumer> localConsumer = [self.localBus subscribeLocal:topicFilter handler:handler];
  if (retainCount == 0) {
    dispatch_async(self.queue, ^{
        [self.mqtt subscribe:topicFilter withCompletionHandler:^(NSArray *grantedQos) {
            // The client is effectively subscribed to the topic filter when this completion handler is called
            NSLog(@"subscribed to topic filter: %@", topicFilter);
        }];
    });
  }

  __block GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topicFilter];
  consumer.unsubscribeBlock = ^{
      [localConsumer unsubscribe];
      int retain = [weakSelf.localBus.topicsManager retainCountOfTopic:topicFilter];
      if (retain == 0) {
        [weakSelf.mqtt unsubscribe:topicFilter withCompletionHandler:^{
            NSLog(@"unsubscribed to topic filter: %@", topicFilter);
        }];
      }
  };
  return consumer;
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  return [self.localBus subscribeLocal:topicFilter handler:handler];
}

- (void)sendOrPub:(GDCMessageImpl *)message {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[message toDictWithTopic:NO]
                                                     options:0
                                                       error:&error];
  if (!jsonData) {
    @throw [NSException exceptionWithName:@"JSON" reason:[NSString stringWithFormat:@"Failed to encode as JSON: %@", error] userInfo:nil];
  }
  dispatch_async(self.queue, ^{
      [self.mqtt publishData:jsonData toTopic:message.topic withQos:AtMostOnce retain:NO completionHandler:^(int mid) {
      }];
  });
}
@end