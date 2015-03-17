#import <Foundation/Foundation.h>
#import "GDCAsyncResult.h"

@protocol GDCMessage;

@interface GDCAsyncResultImpl : NSObject <GDCAsyncResult>

@property(nonatomic, readonly, strong) NSError *cause;
@property(nonatomic, readonly) BOOL failed;
@property(nonatomic, readonly, strong) id<GDCMessage> result;

- (instancetype)initWithMessage:(id <GDCMessage>)message withError:(NSError *)error;
@end