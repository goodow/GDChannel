#import <Foundation/Foundation.h>
#import "GDCMessage.h"
#import "GDCBus.h"

static const NSString *payloadKey = @"payload";
static const NSString *replyTopicKey = @"replyTopic";
static const NSString *localKey = @"local";
static const NSString *sendKey = @"send";
static const NSString *errorKey = @"error";

@interface GDCMessageImpl : NSObject <GDCMessage>

@property(nonatomic, readonly, strong) NSString *topic;
@property(nonatomic, readonly, strong) id payload;
@property(nonatomic, readonly, strong) NSString *replyTopic;
@property(nonatomic, readonly, strong) NSDictionary *dict;
@property(nonatomic) BOOL local;
@property(nonatomic) BOOL send;

@property(nonatomic, strong) id<GDCBus> bus;

+ (NSString *)generateReplyTopic;

- (instancetype)initWithTopic:(NSString *)topic dictionary:(NSDictionary *)dict;

- (instancetype)initWithTopic:(NSString *)topic payload:(id)payload replyTopic:(NSString *)replyTopic send:(BOOL)send local:(BOOL)local;

@end