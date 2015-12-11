//
// Created by Larry Tin on 15/12/9.
//

#import "GDCOptions.h"


@implementation GDCOptions {

}
+ (GDCOptions *)createWithViewOptions {
  GDCOptions *options = [[GDCOptions alloc] init];
  options.viewOptions = [[GDCViewOptions alloc] init];
  return options;
}

- (id)copyWithZone:(NSZone *)zone {
  GDCOptions *copy = [[[self class] allocWithZone:zone] init];

  if (copy != nil) {
    copy.retained = self.retained;
    copy.patch = self.patch;
    copy.type = self.type;
    copy.viewOptions = self.viewOptions;
    copy.extras = self.extras;
  }

  return copy;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
  return NO;
}
- (void)addOrRemoveObserverForEntry:(Class)entry parentKey:(NSString *)parentKey isAdd:(BOOL)isAdd {
}

@end