#import <Foundation/Foundation.h>
#import "GDCMessage.h"

@interface GDCMessageImpl : NSObject <GDCMessage>

@property(nonatomic, readonly, strong) id payload;
@property(nonatomic, readonly, strong) NSString *replyTopic;
@property(nonatomic, readonly, strong) NSString *topic;

@property(nonatomic, strong) id<GDCBus> bus;

- (instancetype)initWithTopic:(NSString *)topic withPayload:(id)payload withReplyTopic:(NSString *)replyTopic;
@end