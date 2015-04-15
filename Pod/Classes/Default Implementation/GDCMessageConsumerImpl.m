#import "GDCMessageConsumerImpl.h"

@implementation GDCMessageConsumerImpl {
  NSString *_topic;
  BOOL _unsubscribed;
}

- (instancetype)initWithTopic:(NSString *)topic {
  self = [super init];
  if (self) {
    _topic = topic;
  }

  return self;
}

- (void)unsubscribe {
  if (!_unsubscribed) {
    self.unsubscribeBlock();
    self.unsubscribeBlock = nil;
    _unsubscribed = YES;
  }
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"_topic=%@", _topic];
  [description appendFormat:@", _unsubscribed=%d", _unsubscribed];
  [description appendFormat:@", self.unsubscribeBlock=%p", self.unsubscribeBlock];
  [description appendString:@">"];
  return description;
}

- (void)dealloc {
  if (!_unsubscribed) {
    NSLog(@"Warning: not %@ %@ when dealloc", NSStringFromSelector(@selector(unsubscribe)), self);
  }
}
@end