#import "GDCMessageImpl.h"

@implementation GDCMessageImpl

+ (NSString *)generateReplyTopic:(NSString *)topic {
  return [NSString stringWithFormat:@"reply/%@/%@", [[NSUUID alloc] init].UUIDString, topic];
}

- (void)reply:(id)payload {
  [self reply:payload options:nil replyHandler:nil];
}

- (void)reply:(id)payload options:(NSDictionary *)options {
  [self reply:payload options:options replyHandler:nil];
}

- (void)reply:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  [self reply:payload options:nil replyHandler:replyHandler];
}

- (void)reply:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  if (self.bus && self.replyTopic) {
    if (self.local) {
      [self.bus sendLocal:self.replyTopic payload:payload options:options replyHandler:replyHandler];
    } else {
      [self.bus send:self.replyTopic payload:payload options:options replyHandler:replyHandler];
    }
  }
}

- (void)fail:(NSError *)error {
  [self reply:error ?: [NSError errorWithDomain:NSStringFromClass(self.class) code:-1 userInfo:nil] replyHandler:nil];
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
  if (self.options) {
    dict[optionsKey] = self.options;
  }
  return dict;
}

- (NSString *)description {
  return [self toDictWithTopic:YES].description;
}

- (id)copyWithZone:(nullable NSZone *)zone {
  GDCMessageImpl *copy = [[GDCMessageImpl allocWithZone:zone] init];
  copy.payload = self.payload;
  copy.topic = self.topic;
  copy.replyTopic = self.replyTopic;
  copy.bus = self.bus;
  copy.local = self.local;
  copy.send = self.send;
  copy.options = self.options;
  return copy;
}

@end