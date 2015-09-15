#import <Foundation/Foundation.h>
#import "GDCMessageHandler.h"
#import "GDCBus.h"

@interface UIViewController (GDChannel) <GDCMessageHandler>

- (id <GDCBus>)bus;

@end