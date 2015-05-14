#import <GDChannel/GDCBus.h>
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCMqttBus.h"
#import "MQTTKit.h"
#import "GDCNotificationBus.h"

@interface GDCMqttBus ()
@property(nonatomic, readonly, strong) GDCNotificationBus *localBus;
@property(nonatomic, readonly, strong) NSMutableDictionary *handlers;
@property(nonatomic, readonly, strong) MQTTClient *mqtt;
@property(nonatomic, readonly, strong) dispatch_queue_t queue;
@end

@implementation GDCMqttBus

- (instancetype)initWithHost:(NSString *)host port:(int)port clientId:(NSString *)clientId {
  self = [super init];
  if (self) {
    _localBus = [[GDCNotificationBus alloc] init];
    _handlers = [NSMutableDictionary dictionary];
    _mqtt = [[MQTTClient alloc] initWithClientId:clientId];
    _mqtt.port = port;
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
            GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:message.topic dictionary:json];
            [weakSelf.localBus sendOrPub:msg replyHandler:nil];
        });
    }];

    // connect the MQTT client
    dispatch_barrier_async(_queue, ^{
        [weakSelf.mqtt connectToHost:host completionHandler:^(MQTTConnectionReturnCode code) {
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
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:nil send:NO local:NO];
  [self sendOrPub:msg];
  return self;
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  [self.localBus publishLocal:topic payload:payload];
  return self;
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  NSString *replyTopic = nil;
  if (replyHandler) {
    replyTopic = [GDCMessageImpl generateReplyTopic];
    __block id <GDCMessageConsumer> consumer = [self subscribe:replyTopic handler:^(id <GDCMessage> message) {
        [consumer unsubscribe];
        GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
        replyHandler(asyncResult);
    }];
  }

  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:replyTopic send:YES local:NO];
  [self sendOrPub:msg];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  [self.localBus sendLocal:topic payload:payload replyHandler:replyHandler];
  return self;
}

- (id <GDCMessageConsumer>)subscribe:(NSString *)topic handler:(GDCMessageHandler)handler {
  __weak GDCMqttBus *weakSelf = self;
  id <GDCMessageConsumer> localConsumer = [self.localBus subscribeToTopic:topic handler:handler bus:self];
  int count = [self.handlers[topic] intValue];
  if (count == 0) {
    dispatch_async(self.queue, ^{
        [weakSelf.mqtt subscribe:topic withCompletionHandler:^(NSArray *grantedQos) {
            // The client is effectively subscribed to the topic when this completion handler is called
            NSLog(@"subscribed to topic %@", topic);
        }];
    });
  }
  self.handlers[topic] = @(++count);

  __block GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topic];
  consumer.unsubscribeBlock = ^{
      [localConsumer unsubscribe];
      int ct = [weakSelf.handlers[topic] intValue];
      weakSelf.handlers[topic] = @(--ct);
      if (ct == 0) {
        [weakSelf.handlers removeObjectForKey:topic];
        [weakSelf.mqtt unsubscribe:topic withCompletionHandler:^{
            NSLog(@"unsubscribed to topic %@", topic);
        }];
      }
  };
  return consumer;
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler {
  return [self.localBus subscribeLocal:topic handler:handler];
}

- (void)sendOrPub:(GDCMessageImpl *)message {
  if (message.dict[errorKey]) {
    NSError *error = message.dict[errorKey];
    ((NSMutableDictionary *) message.dict)[errorKey] = @{@"domain" : error.domain, @"code" : @(error.code), @"userInfo" : error.userInfo};
  }
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message.dict
                                                     options:0
                                                       error:&error];
  if (!jsonData) {
    @throw [NSException exceptionWithName:@"JSON" reason:[NSString stringWithFormat:@"Failed to encode as JSON: %@", error] userInfo:nil];
  }
  [self.mqtt publishData:jsonData toTopic:message.topic withQos:AtMostOnce retain:NO completionHandler:^(int mid) {

  }];
}
@end