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
    if (message.options.timeout != -1) {
      __weak id <GDCBus> weakBus = self;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, message.options.timeout * NSEC_PER_MSEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
          NSError *error = [NSError errorWithDomain:NSStringFromClass(weakBus.class) code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey : @"Timed out waiting for a reply"}];
//          [weakBus sendLocal:message.replyTopic payload:error replyHandler:nil];
      });
    }
  }

  if (!message.send || !message.local) {
    // 如果没有订阅, 应该短路返回
    id payload = message.payload = [self typeCastAndPatch:message];
    if ([payload conformsToProtocol:@protocol(GDCEntry)]) {
      [payload addTopic:message.topic options:message.options];
    }

    if (message.options.retained) {
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
    copied.options.retained = NO;
    [self.notificationCenter postNotificationName:filter object:object userInfo:@{messageKey : copied}];
  }
}

- (id)typeCastAndPatch:(GDCMessageImpl *)message {
  id newPayload = [GDCNotificationBus parseAnyType:message.payload];
  BOOL patch = message.options.patch;
  if (!newPayload && !patch) {
    return nil;
  }
  id oldPayload = patch ? [self.storage getPayload:message.topic] : nil;
  if (!patch || !oldPayload) {
    if ([newPayload isKindOfClass:NSArray.class] && [newPayload count] > 0) { // newPayload 是数组
      NSMutableArray *array = [NSMutableArray arrayWithCapacity:[newPayload count]];
      for (id ele in newPayload) {
        [array addObject:[GDCNotificationBus parseAnyType:ele]];
      }
      return array;
    } // newPayload 是数组
    return newPayload;
  }

  // 存在 oldPayload 且是 patch
  if ([oldPayload isKindOfClass:NSMutableArray.class] && [newPayload isKindOfClass:NSArray.class]) {  // oldPayload 是数组
    for (id ele in newPayload) {
      [oldPayload addObject:[GDCNotificationBus parseAnyType:ele]];
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
        if ([retained.payload conformsToProtocol:@protocol(GDCEntry)]) {
          [retained.payload addTopic:retained.topic options:retained.options];
        }
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

#pragma mark Well-known types

+ (id)parseAnyType:(id)any {
  if ([any isKindOfClass:NSDictionary.class] && any[kJsonTypeKey]) {
    Class<GDCSerializable> dataClass = NSClassFromString([self getType:any[kJsonTypeKey]]);
    if ([dataClass conformsToProtocol:@protocol(GDCSerializable)]) {
      NSError *error = nil;
      any = [dataClass parseFromJson:any error:&error];
    }
  }
  return any;
}

+ (NSString *)getType:(NSString *)typeUrl {
  NSArray<NSString *> *parts = [typeUrl componentsSeparatedByString:@"/"];
  if (parts.count == 1) {
    NSLog(@"Invalid type url found: %@", typeUrl);
  }
  parts = [parts.lastObject componentsSeparatedByString:@"."];
  return parts.lastObject;
}
@end