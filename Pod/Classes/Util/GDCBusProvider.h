#import <Foundation/Foundation.h>
#import "GDCBus.h"

@interface GDCBusProvider : NSObject

+ (id <GDCBus>)instance;

+ (NSString *)clientId;

+ (void)setInstance:(id <GDCBus>)bus;

+ (void)setClientId:(NSString *)clientId;

+ (void)redirectTopic:(NSString *)from to:(NSString *)to;
@end