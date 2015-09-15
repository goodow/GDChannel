#import <Foundation/Foundation.h>

@protocol GDCMessage;

@protocol GDCMessageHandler

- (void)handleMessage:(id <GDCMessage>)message;

@end