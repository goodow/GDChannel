#import <Foundation/Foundation.h>
#import "GDCMessage.h"
#import "GDCAsyncResult.h"
#import "GDCMessageConsumer.h"

#define GDC_BUS_ON_OPEN @"@realtime/bus/onOpen"
#define GDC_BUS_ON_CLOSE @"@realtime/bus/onClose"
#define GDC_BUS_ON_ERROR @"@realtime/bus/onError"

typedef void (^GDCMessageBlock)(id <GDCMessage> message);

@protocol GDCBus <NSObject>

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload;

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload options:(NSDictionary *)options;

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload;

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options;

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler;

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler;

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler;

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload options:(NSDictionary *)options replyHandler:(GDCAsyncResultBlock)replyHandler;

- (id <GDCMessageConsumer>)subscribe:(NSString *)topicFilter handler:(GDCMessageBlock)handler;

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topicFilter handler:(GDCMessageBlock)handler;

@end
