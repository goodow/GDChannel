#import <Foundation/Foundation.h>
#import "GDCMessage.h"
#import "GDCAsyncResult.h"
#import "GDCMessageConsumer.h"

typedef void (^GDCMessageHandler)(id<GDCMessage> message);

@protocol GDCBus <NSObject>

- (id<GDCBus>)publishLocal:(NSString *)topic payload:(id)payload;

- (id<GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler;

- (id<GDCMessageConsumer>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler;

@end
