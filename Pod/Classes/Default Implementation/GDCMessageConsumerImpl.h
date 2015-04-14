#import <Foundation/Foundation.h>
#import "GDCMessageConsumer.h"

@interface GDCMessageConsumerImpl : NSObject <GDCMessageConsumer>

@property(nonatomic, copy) void (^unsubscribeBlock)(void);

- (instancetype)initWithTopic:(NSString *)topic;

@end