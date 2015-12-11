#import "GDCMessageImpl.h"

@implementation GDCMessageImpl

+ (NSString *)generateReplyTopic:(NSString *)topic {
  return [NSString stringWithFormat:@"reply/%@/%@", [[NSUUID alloc] init].UUIDString, topic];
}

- (void)reply:(id)payload {
  [self reply:payload options:nil replyHandler:nil];
}

- (void)reply:(id)payload options:(GDCOptions *)options {
  [self reply:payload options:options replyHandler:nil];
}

- (void)reply:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  [self reply:payload options:nil replyHandler:replyHandler];
}

- (void)reply:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
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
  } else if ([self.payload conformsToProtocol:@protocol(GDCEntry)]) {
    dict[payloadKey] = [self.payload toDictionary];
  } else if (self.payload) {
    dict[payloadKey] = self.payload;
  }
  if (self.options) {
    dict[optionsKey] = [self.options toDictionary];
  }
  return dict;
}

- (NSString *)description {
  NSString *description = [self toDictWithTopic:YES].description;
  // avoid Mojibake
  NSString *desc = [NSString stringWithCString:[description cStringUsingEncoding:NSUTF8StringEncoding] encoding:NSNonLossyASCIIStringEncoding];
//  desc = [NSString stringWithUTF8String:[description cStringUsingEncoding:[NSString defaultCStringEncoding]]];
  return desc ?: description;
}

- (id)copyWithZone:(nullable NSZone *)zone {
  GDCMessageImpl *copy = [[GDCMessageImpl allocWithZone:zone] init];
  copy.payload = self.payload;
  copy.topic = self.topic;
  copy.replyTopic = self.replyTopic;
  copy.bus = self.bus;
  copy.local = self.local;
  copy.send = self.send;
  copy.options = [self.options copyWithZone:zone];
  return copy;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  [coder encodeObject:self.payload forKey:payloadKey];
  [coder encodeObject:self.topic forKey:topicKey];
  [coder encodeObject:self.replyTopic forKey:replyTopicKey];
  [coder encodeBool:self.local forKey:localKey];
  [coder encodeBool:self.send forKey:sendKey];
  [coder encodeObject:self.options forKey:optionsKey];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self.payload = [coder decodeObjectForKey:payloadKey];
  self.topic = [coder decodeObjectForKey:topicKey];
  self.replyTopic = [coder decodeObjectForKey:replyTopicKey];
  self.local = [coder decodeBoolForKey:localKey];
  self.send = [coder decodeBoolForKey:sendKey];
  self.options = [coder decodeObjectForKey:optionsKey];
  return self;
}

@end