#import "GDCBusProvider.h"

#ifdef DEBUG
#import "GDCMqttBus.h"
#else
#import "GDCNotificationBus.h"
#endif

@implementation GDCBusProvider

+ (id <GDCBus>)instance {
  static id <GDCBus> instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
#ifdef DEBUG
      instance = [[GDCMqttBus alloc] initWithHost:@"realtime.goodow.com"];
#else
      instance = [[GDCNotificationBus alloc] init];
#endif
  });

  return instance;
}

@end