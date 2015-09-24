//
// Created by Larry Tin on 15/9/24.
//

#import "NSObject+GDChannel.h"
#import "GDCBusProvider.h"

@implementation NSObject (GDChannel)

- (id <GDCBus>)bus {
  return [GDCBusProvider instance];
}

- (void)handleMessage:(id <GDCMessage>)message {
}

@end