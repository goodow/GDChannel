#import <Foundation/Foundation.h>
#import "GDCMessage.h"
#import "GDCAsyncResult.h"
#import "GDCMessageConsumer.h"

#define GDC_BUS_ON_OPEN @"@realtime/bus/onOpen"
#define GDC_BUS_ON_CLOSE @"@realtime/bus/onClose"
#define GDC_BUS_ON_ERROR @"@realtime/bus/onError"
typedef void (^GDCMessageHandler)(id<GDCMessage> message);

@protocol GDCBus <NSObject>

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload;
- (id<GDCBus>)publishLocal:(NSString *)topic payload:(id)payload;

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler;
- (id<GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler;

- (id <GDCMessageConsumer>)subscribe:(NSString *)topic handler:(GDCMessageHandler)handler;
- (id<GDCMessageConsumer>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler;

@end
