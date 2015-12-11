//
// Created by Larry Tin on 15/12/9.
//

#import "GDCOptions.h"


@implementation GDCOptions {

}
+ (GDCOptions *)options {
  GDCOptions *options = [[GDCOptions alloc] init];
  options.viewOptions = [[GDCViewOptions alloc] init];
  return options;
}
@end