#import <GDChannel/GDCBus.h>
#import "GDCMessageImpl.h"

@implementation GDCMessageImpl

+ (NSString *)generateReplyTopic {
  return [@"GDCReplyTopic/" stringByAppendingString:[[[NSUUID alloc] init] UUIDString]];
}

- (instancetype)initWithTopic:(NSString *)topic dictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _topic = topic;
    _dict = dict;
  }
  return self;
}

- (instancetype)initWithTopic:(NSString *)topic payload:(id)payload replyTopic:(NSString *)replyTopic send:(BOOL)send local:(BOOL)local {
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:4];
  dict[sendKey] = @(send);
  dict[localKey] = @(local);
  if (replyTopic) {
    dict[replyTopicKey] = replyTopic;
  }
  if ([payload isKindOfClass:NSError.class]) {
    dict[errorKey] = payload;
  } else if (payload) {
    dict[payloadKey] = payload;
  }

  return [self initWithTopic:topic dictionary:dict];
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton"
                                 reason:[NSString stringWithFormat:@"Use %@ %@", NSStringFromClass(GDCMessageImpl.class), NSStringFromSelector(@selector(initWithTopic:payload:replyTopic:send:local:))]
                               userInfo:nil];
}

- (void)reply:(id)payload {
  [self reply:payload replyHandler:nil];
}

- (void)reply:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler {
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

- (id)payload {
  return self.dict[payloadKey];
}

- (NSString *)replyTopic {
  return self.dict[replyTopicKey];
}

- (BOOL)local {
  return [self.dict[localKey] boolValue];
}

- (BOOL)send {
  return [self.dict[sendKey] boolValue];
}

- (NSString *)description {
  NSMutableDictionary *all = [NSMutableDictionary dictionaryWithDictionary:self.dict];
  all[@"topic"] = self.topic;
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:all
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  if (!jsonData) {
    return [NSString stringWithFormat:@"Failed to encode as JSON: %@", error];
  }
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
@end