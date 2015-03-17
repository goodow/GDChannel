#import <GDChannel/GDCBus.h>
#import "GDCMessageImpl.h"

@implementation GDCMessageImpl

- (instancetype)initWithTopic:(NSString *)topic withPayload:(id)payload withReplyTopic:(NSString *)replyTopic {
  self = [super init];
  if (self) {
    _payload = payload;
    _topic = topic;
    _replyTopic = replyTopic;
  }
  return self;
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton" reason:@"Use [[GDCMessageImpl alloc] initWithTopic: withPayload:]" userInfo:nil];
}

- (void)reply:(id)payload {
  [self reply:payload replyHandler:nil];
}

- (void)reply:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
  if (self.bus && self.replyTopic) {
    [self.bus sendLocal:self.replyTopic payload:payload replyHandler:replyHandler];
  }
}

@end