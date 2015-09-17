#import "GDCMessageImpl.h"

@implementation GDCMessageImpl

+ (NSString *)generateReplyTopic {
  return [@"GDCReplyTopic/" stringByAppendingString:[[[NSUUID alloc] init] UUIDString]];
}

- (void)reply:(id)payload {
  [self reply:payload replyHandler:nil];
}

- (void)reply:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  if (self.bus && self.replyTopic) {
    if (self.local) {
      [self.bus sendLocal:self.replyTopic payload:payload replyHandler:replyHandler];
    } else {
      [self.bus send:self.replyTopic payload:payload replyHandler:replyHandler];
    }
  }
}

- (void)fail:(NSError *)error {
  [self reply:error replyHandler:nil];
}

- (NSDictionary *)toDictWithTopic:(BOOL)containsTopic {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:5];
  if (containsTopic) {
    dict[topicKey] = self.topic;
  }
  if (self.send) {
    dict[sendKey] = @(self.send);
  }
  if (self.local) {
    dict[localKey] = @(self.local);
  }
  if (self.replyTopic) {
    dict[replyTopicKey] = self.replyTopic;
  }
  if ([self.payload isKindOfClass:NSError.class]) {
    NSError *error = self.payload;
    dict[errorKey] = @{errorDomainKey : error.domain, errorCodeKey : @(error.code), errorUserInfoKey : error.userInfo};
  } else if (self.payload) {
    dict[payloadKey] = self.payload;
  }
  return dict;
}

- (NSString *)description {
  return [self toDictWithTopic:YES].description;
}
@end