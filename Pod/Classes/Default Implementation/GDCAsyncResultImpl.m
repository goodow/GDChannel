#import "GDCAsyncResultImpl.h"
#import "GDCMessage.h"

@implementation GDCAsyncResultImpl
- (instancetype)initWithMessage:(id<GDCMessage>)message withError:(NSError *)error {
  self = [super init];
  if (self) {
    _result = message;
    _cause = error;
    if (error) {
      _failed = YES;
    }
  }

  return self;
}

@end