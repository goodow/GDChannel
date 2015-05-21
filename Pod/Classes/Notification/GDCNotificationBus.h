#import <Foundation/Foundation.h>
#import <GDChannel/GDCMessage.h>
#import <GDChannel/GDCBus.h>
#import "GDCBus.h"

@class GDCMessageImpl;
@class GDCMessageConsumerImpl;
@class GDCTopicsManager;

@interface GDCNotificationBus : NSObject <GDCBus>

@property(nonatomic, readonly, strong) GDCTopicsManager *topicsManager;

- (void)sendOrPub:(GDCMessageImpl *)message replyHandler:(GDCAsyncResultHandler)replyHandler;

- (GDCMessageConsumerImpl *)subscribeToTopic:(NSString *)topicFilter handler:(GDCMessageHandler)handler bus:(id <GDCBus>)bus;

@end