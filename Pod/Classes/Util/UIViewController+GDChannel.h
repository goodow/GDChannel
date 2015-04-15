#import <Foundation/Foundation.h>
#import "GDCMessageObserver.h"

@protocol GDCBus;

@interface UIViewController (GDChannel) <GDCMessageObserver>

- (id <GDCBus>)bus;

@end