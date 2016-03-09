#import "GDCBus.h"
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCTopicsManager.h"
#import "GDCStorage.h"

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
  }

  if (!message.send || !message.local) {
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
    GDCMessageImpl *copied = message.copy;
    copied.options.retained = NO;
    [self.notificationCenter postNotificationName:filter object:object userInfo:@{messageKey : copied}];
  }
}

- (id)typeCastAndPatch:(GDCMessageImpl *)message {
  id newPayload = message.payload;
  if (!newPayload) {
    return nil;
  }
  NSString *type = message.options.type;
  BOOL patch = message.options.patch;
  BOOL isEntry = [newPayload conformsToProtocol:@protocol(GDCEntry)];
  id oldPayload;
  BOOL shouldInferType = !isEntry && !type;
  if (shouldInferType || patch) {
    oldPayload = [self.storage getPayload:message.topic];
    if (shouldInferType && [oldPayload conformsToProtocol:@protocol(GDCEntry)]) {
      // 根据 oldPayload 推断 type 和 patch
      type = NSStringFromClass([oldPayload class]);
      patch = YES;
    }
  }

  if (!type) {
    if (!patch || !oldPayload) {
      return newPayload;
    }
    id toRtn = [GDCStorage patchRecursively:oldPayload with:newPayload];
    return isEntry ? [[newPayload class] of:toRtn] : toRtn;
  }

  // 设置了 type
  Class clz = NSClassFromString(type);
  if (!patch || !oldPayload) {
    if ([newPayload isKindOfClass:clz]) {
      return newPayload;
    }
    if (isEntry) {
      newPayload = [(GDCEntry *) newPayload toDictionary];
    }
    return [clz of:newPayload];
  }

  // 设置了 type 和 patch
  NSDictionary *toRtn = [GDCStorage patchRecursively:oldPayload with:newPayload];
  return [clz of:toRtn];
}

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id observer = [self.notificationCenter addObserverForName:topicFilter object:object queue:self.queue usingBlock:^(NSNotification *note) {
      GDCMessageImpl *message = note.userInfo[messageKey];
      [GDCNotificationBus scheduleDeferred:handler argument:message];
  }];
  [self.topicsManager addSubscribedTopicFilter:topicFilter];

  GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topicFilter];
  consumer.unsubscribeBlock = ^{
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopicFilter:topicFilter];
  };

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      GDCMessageImpl *retained = [self.storage getRetainedMessage:topicFilter];
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

      GDCMessageImpl *message = note.userInfo[messageKey];
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