#import "GDCBus.h"
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCTopicsManager.h"

static const NSString *object = @"GDCNotificationBus/object";
static const NSString *messageKey = @"msg";

@interface GDCNotificationBus ()
@property(nonatomic, readonly, strong) NSNotificationCenter *notificationCenter;
@property(nonatomic, readonly, strong) NSOperationQueue *queue;
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self publishLocal:GDC_BUS_ON_OPEN payload:@{}];
    });
  }
  return self;
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload {
  return [self publish:topic payload:payload options:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload options:(NSDictionary *)options {
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

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options {
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

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
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

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
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

  NSSet *topicsToPublish = [self.topicsManager calculateTopicsToPublish:message.topic];
  BOOL first = YES;
  for (NSString *filter in topicsToPublish) {
    [self.notificationCenter postNotificationName:filter object:object userInfo:@{messageKey : first ? message : message.copy}];
    first = NO;
  }
}

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id observer = [self.notificationCenter addObserverForName:topicFilter object:object queue:self.queue usingBlock:^(NSNotification *note) {
      GDCMessageImpl *message = note.userInfo[messageKey];
      [weakSelf scheduleDeferred:handler argument:message];
  }];
  [self.topicsManager addSubscribedTopic:topicFilter];

  GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topicFilter];
  consumer.unsubscribeBlock = ^{
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopic:topicFilter];
  };
  return consumer;
}

- (void)subscribeToReplyTopic:(NSString *)replyTopic replyHandler:(GDCAsyncResultBlock)replyHandler {
  __weak GDCNotificationBus *weakSelf = self;
  __weak __block id <NSObject> observer = [self.notificationCenter addObserverForName:replyTopic object:object queue:self.queue usingBlock:^(NSNotification *note) {
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopic:replyTopic];

      GDCMessageImpl *message = note.userInfo[messageKey];
      GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
      [weakSelf scheduleDeferred:replyHandler argument:asyncResult];
  }];
  [self.topicsManager addSubscribedTopic:replyTopic];
}

- (void)scheduleDeferred:(void (^)(id))block argument:(id)argument {
//  [[NSRunLoop mainRunLoop] performSelector:@selector(performBlock:) target:self argument:@[block, argument] order:0 modes:@[NSRunLoopCommonModes]];
  [self performSelectorOnMainThread:@selector(performBlock:) withObject:@[block, argument] waitUntilDone:NO];
}

- (void)performBlock:(NSArray *)arguments {
  void (^block)(id) = arguments[0];
  block(arguments[1]);
}
@end