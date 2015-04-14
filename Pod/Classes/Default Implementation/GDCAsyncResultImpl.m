#import "GDCAsyncResultImpl.h"
#import "GDCMessage.h"
#import "GDCMessageImpl.h"

@implementation GDCAsyncResultImpl
- (instancetype)initWithMessage:(GDCMessageImpl *)message {
  self = [super init];
  if (self) {
    _result = message;
    _cause = message.dict[errorKey];
    if (_cause) {
      _failed = YES;
    }
  }

  return self;
}

@end