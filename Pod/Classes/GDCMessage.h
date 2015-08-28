#import <Foundation/Foundation.h>

@protocol GDCAsyncResult;
typedef void (^GDCAsyncResultHandler)(id<GDCAsyncResult> asyncResult);

@protocol GDCMessage <NSObject>

@property(nonatomic, readonly) id payload;
@property(nonatomic, readonly) NSString *topic;
@property(nonatomic, readonly) NSString *replyTopic;

- (void)reply:(id)payload;

- (void)reply:(id)payload replyHandler:(GDCAsyncResultHandler)replyHandler;

- (void)fail:(NSError *)error;

@end