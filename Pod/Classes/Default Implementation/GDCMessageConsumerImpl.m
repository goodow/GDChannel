#import "GDCMessageConsumerImpl.h"

@implementation GDCMessageConsumerImpl {
  NSString *_topic;
}

- (instancetype)initWithTopic:(NSString *)topic {
  self = [super init];
  if (self) {
    _topic = topic;
  }

  return self;
}

- (void)unsubscribe {
  self.unsubscribeBlock();
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"_topic=%@", _topic];
  [description appendFormat:@", self.unsubscribeBlock=%p", self.unsubscribeBlock];
  [description appendString:@">"];
  return description;
}

@end