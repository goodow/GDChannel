#import <Foundation/Foundation.h>
#import "GDCOptions.h"

static const NSString *replyTopicPrefix = @"reply/+/";

@protocol GDCAsyncResult;

typedef void (^GDCAsyncResultBlock)(id<GDCAsyncResult> asyncResult);

@protocol GDCMessage <NSObject, NSCoding, NSCopying>

@property(nonatomic, readonly) __kindof id payload;
@property(nonatomic, readonly) NSString *topic;
@property(nonatomic, readonly) NSString *replyTopic;
@property(nonatomic, readonly) GDCOptions *options;

- (void)reply:(id)payload;
- (void)reply:(id)payload options:(GDCOptions *)options;

- (void)reply:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler;
- (void)reply:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler;

- (void)fail:(NSError *)error;

@end