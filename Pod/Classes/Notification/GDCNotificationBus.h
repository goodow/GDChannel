#import <Foundation/Foundation.h>
#import <GDChannel/GDCMessage.h>
#import <GDChannel/GDCBus.h>
#import "GDCBus.h"

@class GDCMessageImpl;
@class GDCMessageConsumerImpl;

@interface GDCNotificationBus : NSObject <GDCBus>

- (void)sendOrPub:(GDCMessageImpl *)message replyHandler:(GDCAsyncResultHandler)replyHandler;

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topic handler:(GDCMessageHandler)handler bus:(id <GDCBus>)bus;

- (void)subscribeToReplyTopic:(NSString *)replyTopic replyHandler:(GDCAsyncResultHandler)replyHandler bus:(id <GDCBus>)bus;

@end