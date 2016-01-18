//
// Created by Larry Tin on 15/9/24.
//

#import "NSObject+GDChannel.h"
#import "GDCBusProvider.h"
#import "GDCEntry.h"
#import <objc/runtime.h>

@implementation NSObject (GDChannel)

- (id <GDCBus>)bus {
  return [GDCBusProvider instance];
}

- (void)handleMessage:(id <GDCMessage>)message {

}

@end

@implementation UIViewController (GDChannel)

- (GDCViewOptions *)viewOptions {
  return objc_getAssociatedObject(self, _GDCViewOptionsAssociatedKey);;
}

@end