//
// Created by Larry Tin on 15/9/24.
//

#import "NSObject+GDChannel.h"
#import "GDCBusProvider.h"
#import <objc/runtime.h>

@implementation NSObject (GDChannel)

- (id <GDCBus>)bus {
  return [GDCBusProvider instance];
}

- (id <GDCMessage>)message {
  return objc_getAssociatedObject(self, _GDCMessageAssociatedKey);
}

- (void)handleMessage:(id <GDCMessage>)message {
  objc_setAssociatedObject(self, _GDCMessageAssociatedKey, message, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end