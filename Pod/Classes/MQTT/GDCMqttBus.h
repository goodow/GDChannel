#import <Foundation/Foundation.h>
#import "GDCBus.h"
#import "GDCNotificationBus.h"

@interface GDCMqttBus : NSObject <GDCBus>

@property(nonatomic, readonly, strong) GDCNotificationBus *localBus;

- (instancetype)initWithHost:(NSString *)host port:(int)port localBus:(GDCNotificationBus *)localBus clientId:(NSString *)clientId;
@end