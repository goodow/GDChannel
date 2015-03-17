#import "GDCBusProvider.h"
#import "GDCNotificationBus.h"

@implementation GDCBusProvider

+ (id <GDCBus>)sharedBus {
  static GDCNotificationBus *sharedBus;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedBus = [[GDCNotificationBus alloc] init];
  });

  return sharedBus;
}

@end