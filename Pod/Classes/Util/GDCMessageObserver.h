#import <Foundation/Foundation.h>

@protocol GDCMessage;

@protocol GDCMessageObserver

- (void)receivedWithMessage:(id <GDCMessage>)message;

@end