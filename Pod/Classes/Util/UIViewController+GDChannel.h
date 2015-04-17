#import <Foundation/Foundation.h>
#import "GDCMessageObserver.h"
#import "GDCBus.h"

@interface UIViewController (GDChannel) <GDCMessageObserver>

- (id <GDCBus>)bus;

@end