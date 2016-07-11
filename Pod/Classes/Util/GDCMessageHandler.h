#import <Foundation/Foundation.h>
#import "GDCMessage.h"

@protocol GDCMessageHandler

- (void)handleMessage:(id <GDCMessage>)message;

@optional
- (instancetype)initWithPayload:(id)payload;

@end