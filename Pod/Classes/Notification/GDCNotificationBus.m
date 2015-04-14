#import <GDChannel/GDCBus.h>
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"

static const NSString *object = @"GDCNotificationBus/object";

@interface GDCNotificationBus ()
@property(nonatomic, readonly, strong) NSNotificationCenter *notificationCenter;
@end

@implementation GDCNotificationBus

- (instancetype)init {
  self = [super init];
  if (self) {
    _notificationCenter = [NSNotificationCenter defaultCenter];
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

- (id <GDCMessageConsumer>)subscribe:(NSString *)topic handler:(GDCMessageHandler)handler {
  return [self subscribeLocal:topic handler:handler];
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler {
  return [self subscribeToTopic:topic handler:handler bus:self];
}

- (void)sendOrPub:(GDCMessageImpl *)message replyHandler:(GDCAsyncResultHandler)replyHandler {
  if (replyHandler) {
    [self subscribeToReplyTopic:message.replyTopic replyHandler:replyHandler bus:self];
  }

  [self.notificationCenter postNotificationName:message.topic object:object userInfo:message.dict];
}

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topic handler:(GDCMessageHandler)handler bus:(id <GDCBus>)bus {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id <GDCBus> weakBus = bus;
  id observer = [self.notificationCenter addObserverForName:topic object:object queue:nil usingBlock:^(NSNotification *note) {
      GDCMessageImpl *message = [[GDCMessageImpl alloc] initWithTopic:note.name dictionary:note.userInfo];
      message.bus = weakBus;
      handler(message);
  }];
  GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] initWithTopic:topic];
  consumer.unsubscribeBlock = ^{
      [weakSelf.notificationCenter removeObserver:observer];
  };
  return consumer;
}

- (void)subscribeToReplyTopic:(NSString *)replyTopic replyHandler:(GDCAsyncResultHandler)replyHandler bus:(id <GDCBus>)bus {
  __weak GDCNotificationBus *weakSelf = self;
  __weak id <GDCBus> weakBus = bus;
  __block id <NSObject> observer = [self.notificationCenter addObserverForName:replyTopic object:object queue:nil usingBlock:^(NSNotification *note) {
      [weakSelf.notificationCenter removeObserver:observer];
      observer = nil;

      GDCMessageImpl *message = [[GDCMessageImpl alloc] initWithTopic:note.name dictionary:note.userInfo];
      message.bus = weakBus;
      GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
      replyHandler(asyncResult);
  }];
}

@end