#import "GDCBusProvider.h"
#import "GDCMqttBus.h"

@implementation GDCBusProvider

static NSString *clientId;
static id <GDCBus> instance;

+ (id <GDCBus>)instance {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      if (instance) {
        return;
      }
#ifdef DEBUG
      instance = [[GDCMqttBus alloc] initWithHost:@"realtime.goodow.com" port:1883 localBus:nil clientId:[GDCBusProvider clientId]];
#else
      instance = [[GDCNotificationBus alloc] init];
#endif
  });

  return instance;
}

+ (NSString *)clientId {
  if (!clientId) {
    clientId = UIDevice.currentDevice.identifierForVendor.UUIDString;
  }
  return clientId;
}

+ (void)setInstance:(id <GDCBus>)bus {
  if (instance) {
    NSLog(@"Error: bus is already set, ignore");
    return;
  }
  instance = bus;
}

+ (void)setClientId:(NSString *)newClientId {
  if (clientId) {
    NSLog(@"Error: clientId is already set, ignore");
    return;
  }
  clientId = newClientId;
}
@end