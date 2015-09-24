#import <Foundation/Foundation.h>

static const NSString *replyTopicPrefix = @"reply/+/";

@protocol GDCAsyncResult;
typedef void (^GDCAsyncResultBlock)(id<GDCAsyncResult> asyncResult);

@protocol GDCMessage <NSObject>

@property(nonatomic, readonly) id payload;
@property(nonatomic, readonly) NSString *topic;
@property(nonatomic, readonly) NSString *replyTopic;

- (void)reply:(id)payload;

- (void)reply:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler;

- (void)fail:(NSError *)error;

@end