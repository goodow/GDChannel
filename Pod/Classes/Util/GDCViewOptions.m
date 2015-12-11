//
// Created by Larry Tin on 15/12/9.
//

#import "GDCViewOptions.h"

@implementation GDCViewOptions {

}
- (instancetype)init {
  self = [super init];
  if (self) {
    _edgesForExtendedLayout = UIRectEdgeAll;
    _navBar = YES;
    _statusBar = YES;
  }

  return self;
}



@end