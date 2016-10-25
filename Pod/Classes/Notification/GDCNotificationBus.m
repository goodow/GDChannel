#import "GDCBus.h"
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCTopicsManager.h"
#import "GDCStorage.h"
#import "GPBMessage+JsonFormat.h"
#import "NSMutableArray+GDCSerializable.h"
#import "NSMutableDictionary+GDCSerializable.h"
#import "GPBAny+GDChannel.h"
#import "GDCOptions+ReadAccess.h"

static const NSString *object = @"GDCNotificationBus/object";
static const NSString *messageKey = @"msg";

@interface GDCNotificationBus ()
@property(nonatomic, readonly, strong) NSNotificationCenter *notificationCenter;
@property(nonatomic, readonly, strong) NSOperationQueue *queue;
@property(nonatomic, readonly, strong) GDCStorage *storage;
@end

@implementation GDCNotificationBus

- (instancetype)init {
  self = [super init];
  if (self) {
    _notificationCenter = [NSNotificationCenter defaultCenter];
    _topicsManager = [[GDCTopicsManager alloc] init];
    _queue = [[NSOperationQueue alloc] init];
    _queue.name = @"GDChannel dispatch queue";
    _queue.maxConcurrentOperationCount = 1;
    _storage = GDCStorage.instance;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self publishLocal:GDC_BUS_ON_OPEN payload:@{}];
    });
  }
  return self;
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload {
  return [self publish:topic payload:payload options:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload options:(GDCOptions *)options {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.options = options;
  [self sendOrPub:msg replyHandler:nil];
  return self;
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  return [self publishLocal:topic payload:payload options:nil];
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload options:(GDCOptions *)options {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.local = YES;
  msg.options = options;
  [self sendOrPub:msg replyHandler:nil];
  return self;
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self send:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.send = YES;
  msg.options = options;
  if (replyHandler) {
    msg.replyTopic = [GDCMessageImpl generateReplyTopic:topic];
    msg.bus = self;
  }
  [self sendOrPub:msg replyHandler:replyHandler];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self sendLocal:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = topic;
  msg.payload = payload;
  msg.send = YES;
  msg.local = YES;
  msg.options = options;
  if (replyHandler) {
    msg.replyTopic = [GDCMessageImpl generateReplyTopic:topic];
    msg.bus = self;
  }
  [self sendOrPub:msg replyHandler:replyHandler];
  return self;
}

- (id <GDCMessageConsumer>)subscribe:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  return [self subscribeLocal:topicFilter handler:handler];
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  return [self subscribeToTopic:topicFilter handler:handler];
}

- (void)sendOrPub:(GDCMessageImpl *)message replyHandler:(GDCAsyncResultBlock)replyHandler {
  if (replyHandler) {
    [self subscribeToReplyTopic:message.replyTopic replyHandler:replyHandler];
    if (message.options.getTimeout != -1) {
      __weak id <GDCBus> weakBus = self;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, message.options.getTimeout * NSEC_PER_MSEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
          NSError *error = [NSError errorWithDomain:NSStringFromClass(weakBus.class) code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey : @"Timed out waiting for a reply"}];
//          [weakBus sendLocal:message.replyTopic payload:error replyHandler:nil];
      });
    }
  }

  if (!message.send || !message.local) {
    // 如果没有订阅, 应该短路返回
    id payload = message.payload = [self typeCastAndPatch:message];
    if (message.options.isRetained) {
      if (payload) {
        [self.storage save:message];
      } else {
        [self.storage remove:message.topic];
      }
    } else {
      [self.storage cache:message.topic payload:message.payload];
    }
  }

  NSSet *topicsToPublish = [self.topicsManager calculateTopicFiltersToPublish:message.topic];
  for (NSString *filter in topicsToPublish) {
    // Each handler gets a fresh copy
    id <GDCMessage> copied = message.copy;
    if (copied.options.isRetained) {
      // It MUST set the RETAIN flag to 0 when a PUBLISH Packet is sent to a Client because it matches an established subscription
      // regardless of how the flag was set in the message it received [MQTT-3.3.1-9].
      copied.options.retained(NO);
    }
    [self.notificationCenter postNotificationName:filter object:object userInfo:@{messageKey : copied}];
  }
}

- (id)typeCastAndPatch:(GDCMessageImpl *)message {
  id newPayload = [GPBAny unpackFromJson:message.payload error:nil];
  BOOL patch = message.options.isPatch;
  if (!newPayload && !patch) {
    return nil;
  }
  id oldPayload = patch ? [self.storage getPayload:message.topic] : nil;
  if (!patch || !oldPayload) {
    if ([newPayload isKindOfClass:NSArray.class] && [newPayload count] > 0) { // newPayload 是数组
      NSMutableArray *array = [NSMutableArray arrayWithCapacity:[newPayload count]];
      for (id ele in newPayload) {
        [array addObject:[GPBAny unpackFromJson:ele error:nil]];
      }
      return array;
    } // newPayload 是数组
    return newPayload;
  }

  // 存在 oldPayload 且是 patch
  if ([oldPayload isKindOfClass:NSMutableArray.class] && [newPayload isKindOfClass:NSArray.class]) {  // oldPayload 是数组
    for (id ele in newPayload) {
      [oldPayload addObject:[GPBAny unpackFromJson:ele error:nil]];
    }
    return oldPayload;
  }
  if ([oldPayload conformsToProtocol:@protocol(GDCSerializable)]) {
    if ([newPayload isKindOfClass:NSDictionary.class]) {
      [oldPayload mergeFromJson:newPayload];
    } else {
      [oldPayload mergeFrom:newPayload];
    }
  }
  return oldPayload;
}

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id observer = [self.notificationCenter addObserverForName:topicFilter object:object queue:self.queue usingBlock:^(NSNotification *note) {
      id <GDCMessage> message = note.userInfo[messageKey];
      [GDCNotificationBus scheduleDeferred:handler argument:message];
  }];
  [self.topicsManager addSubscribedTopicFilter:topicFilter];

  GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topicFilter];
  consumer.unsubscribeBlock = ^{
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopicFilter:topicFilter];
  };

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      id <GDCMessage> retained = [self.storage getRetainedMessage:topicFilter];
      if (retained) {
        // When sending a PUBLISH Packet to a Client the Server MUST set the RETAIN flag to 1
        // if a message is sent as a result of a new subscription being made by a Client [MQTT-3.3.1-8]
        [GDCNotificationBus scheduleDeferred:handler argument:retained];
      }
  });
  return consumer;
}

- (void)subscribeToReplyTopic:(NSString *)replyTopic replyHandler:(GDCAsyncResultBlock)replyHandler {
  __weak GDCNotificationBus *weakSelf = self;
  __weak __block id <NSObject> observer = [self.notificationCenter addObserverForName:replyTopic object:object queue:self.queue usingBlock:^(NSNotification *note) {
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopicFilter:replyTopic];

      id <GDCMessage> message = note.userInfo[messageKey];
      GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
      [GDCNotificationBus scheduleDeferred:replyHandler argument:asyncResult];
  }];
  [self.topicsManager addSubscribedTopicFilter:replyTopic];
}

+ (void)scheduleDeferred:(void (^)(id))block argument:(id)argument {
//  [[NSRunLoop mainRunLoop] performSelector:@selector(performBlock:) target:self argument:@[block, argument] order:0 modes:@[NSRunLoopCommonModes]];
  [self performSelectorOnMainThread:@selector(performBlock:) withObject:@[block, argument ?: NSNull.null] waitUntilDone:NO];
}

+ (void)performBlock:(NSArray *)arguments {
  void (^block)(id) = arguments[0];
  block(arguments[1]);
}

@end