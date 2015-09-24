#import <Foundation/Foundation.h>
#import "GDCMessage.h"

@protocol GDCMessageHandler

- (void)handleMessage:(id <GDCMessage>)message;

@end