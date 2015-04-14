#import <Foundation/Foundation.h>
#import "GDCBus.h"

@interface GDCBusProvider : NSObject

+ (id <GDCBus>)instance;

@end