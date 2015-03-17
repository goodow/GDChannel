#import <GDChannel/GDCBus.h>
#import "GDCNotificationBus.h"
#import "GDCMessageImpl.h"
#import "GDCMessageConsumerImpl.h"
#import "GDCAsyncResultImpl.h"

static const NSString *payloadKey = @"payload";
static const NSString *replyTopicKey = @"replyTopic";
static const NSString *object = @"GDCNotificationBus/object";
static const NSString *errorKey = @"error";

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

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  [self.notificationCenter postNotificationName:topic object:object userInfo:payload ? @{payloadKey : payload} : nil];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  NSString *replyTopic;
  if (replyHandler) {
    replyTopic = self.generateReplyTopic;
    __weak GDCNotificationBus *weakSelf = self;
    __block id <NSObject> observer = [self.notificationCenter addObserverForName:replyTopic object:object queue:nil usingBlock:^(NSNotification *note) {
        [weakSelf.notificationCenter removeObserver:observer];
        observer = nil;

        GDCMessageImpl *message = [weakSelf convertMessage:note];
        GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message withError:note.userInfo[errorKey]];
        replyHandler(asyncResult);
    }];
  }
  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
  if (replyTopic) {
    userInfo[replyTopicKey] = replyTopic;
  }
  if (payload) {
    userInfo[payloadKey] = payload;
  }
  [self.notificationCenter postNotificationName:topic object:object userInfo:userInfo];
  return self;
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler {
  __weak GDCNotificationBus *weakSelf = self;
  id observer = [self.notificationCenter addObserverForName:topic object:object queue:nil usingBlock:^(NSNotification *note) {
      GDCMessageImpl *message = [weakSelf convertMessage:note];
      handler(message);
  }];
  GDCMessageConsumerImpl *consumer = [[GDCMessageConsumerImpl alloc] init];
  consumer.unsubscribeBlock = ^{
      [self.notificationCenter removeObserver:observer];
  };
  return consumer;
}

- (GDCMessageImpl *)convertMessage:(NSNotification *)note {
  NSString *replyTopic = note.userInfo[replyTopicKey];
  GDCMessageImpl *message = [[GDCMessageImpl alloc] initWithTopic:note.name withPayload:note.userInfo[payloadKey] withReplyTopic:replyTopic];
  if (replyTopic) {
    message.bus = self;
  }
  return message;
}

- (NSString *)generateReplyTopic {
  return [@"GDCReplyTopic/" stringByAppendingString:[[[NSUUID alloc] init] UUIDString]];
}
@end