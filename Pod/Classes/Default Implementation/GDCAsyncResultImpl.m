#import "GDCAsyncResultImpl.h"
#import "GDCMessage.h"
#import "GDCMessageImpl.h"

@implementation GDCAsyncResultImpl
- (instancetype)initWithMessage:(GDCMessageImpl *)message {
  self = [super init];
  if (self) {
    _result = message;
    if ([message.payload isKindOfClass:NSError.class]) {
      _cause = message.payload;
      _failed = YES;
      message.payload = nil;
    }
  }

  return self;
}

@end