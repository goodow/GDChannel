#import "GDCBusProvider.h"

#ifdef DEBUG
#import "GDCMqttBus.h"
#else
#import "GDCNotificationBus.h"
#endif

@implementation GDCBusProvider

static NSString *clientId;

+ (id <GDCBus>)instance {
  static id <GDCBus> instance;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
#ifdef DEBUG
      instance = [[GDCMqttBus alloc] initWithHost:@"realtime.goodow.com" port:1883 clientId:[GDCBusProvider clientId:nil]];
#else
      instance = [[GDCNotificationBus alloc] init];
#endif
  });

  return instance;
}

+ (NSString *)clientId:(NSString *)newClientId {
  if (clientId) {
    if (newClientId) {
      NSLog(@"Warning: clientId is already set, ignore");
    }
    return clientId;
  }
  clientId = newClientId ? newClientId : [UIDevice currentDevice].identifierForVendor.UUIDString;
  return clientId;
}
@end