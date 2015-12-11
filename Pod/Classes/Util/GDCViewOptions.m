//
// Created by Larry Tin on 15/12/9.
//

#import "GDCViewOptions.h"

@implementation GDCViewOptions {

}
- (instancetype)init {
  self = [super init];
  if (self) {
    _redirect = YES;
    _statusBar = YES;
    _navBar = YES;
    _autorotate = YES;
    _edgesForExtendedLayout = UIRectEdgeAll;
  }

  return self;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  return NO;
}
- (void)addOrRemoveObserverForEntry:(Class)entry parentKey:(NSString *)parentKey isAdd:(BOOL)isAdd {
}

@end