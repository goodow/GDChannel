#import <Foundation/Foundation.h>

@protocol GDCAsyncResult;
typedef void (^GDCAsyncResultHandler)(id<GDCAsyncResult> asyncResult);

@protocol GDCMessage <NSObject>

- (id)payload;

- (void)reply:(id)payload;

- (void)reply:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler;

- (NSString *)replyTopic;

- (NSString *)topic;

@end