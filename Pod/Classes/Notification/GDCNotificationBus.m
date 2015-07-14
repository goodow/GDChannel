#import <GDChannel/GDCBus.h>
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"
#import "GDCTopicsManager.h"

static const NSString *object = @"GDCNotificationBus/object";

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
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:nil send:NO local:NO];
  [self sendOrPub:msg replyHandler:nil];
  return self;
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:nil send:NO local:YES];
  [self sendOrPub:msg replyHandler:nil];
  return self;
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:(replyHandler ? GDCMessageImpl.generateReplyTopic : nil) send:YES local:NO];
  [self sendOrPub:msg replyHandler:replyHandler];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] initWithTopic:topic payload:payload replyTopic:(replyHandler ? GDCMessageImpl.generateReplyTopic : nil) send:YES local:YES];
  [self sendOrPub:msg replyHandler:replyHandler];
  return self;
}

- (id <GDCMessageConsumer>)subscribe:(NSString *)topicFilter handler:(GDCMessageHandler)handler {
  return [self subscribeLocal:topicFilter handler:handler];
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topicFilter handler:(GDCMessageHandler)handler {
  return [self subscribeToTopic:topicFilter handler:handler bus:self];
}

- (void)sendOrPub:(GDCMessageImpl *)message replyHandler:(GDCAsyncResultHandler)replyHandler {
  if (replyHandler) {
    [self subscribeToReplyTopic:message.replyTopic replyHandler:replyHandler bus:self];
  }

  NSSet *topicsToPublish = [self.topicsManager calculateTopicsToPublish:message.topic];
  for (NSString *filter in topicsToPublish) {
    [self.notificationCenter postNotificationName:filter object:object userInfo:message.dict];
  }
}

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topicFilter handler:(GDCMessageHandler)handler bus:(id <GDCBus>)bus {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id <GDCBus> weakBus = bus;
  __weak id observer = [self.notificationCenter addObserverForName:topicFilter object:object queue:self.queue usingBlock:^(NSNotification *note) {
      GDCMessageImpl *message = [[GDCMessageImpl alloc] initWithTopic:note.name dictionary:note.userInfo];
      message.bus = weakBus;
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

- (void)subscribeToReplyTopic:(NSString *)replyTopic replyHandler:(GDCAsyncResultHandler)replyHandler bus:(id <GDCBus>)bus {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id <GDCBus> weakBus = bus;
  __weak __block id <NSObject> observer = [self.notificationCenter addObserverForName:replyTopic object:object queue:self.queue usingBlock:^(NSNotification *note) {
      [weakSelf.notificationCenter removeObserver:observer];
      [weakSelf.topicsManager removeSubscribedTopic:replyTopic];

      GDCMessageImpl *message = [[GDCMessageImpl alloc] initWithTopic:note.name dictionary:note.userInfo];
      message.bus = weakBus;
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