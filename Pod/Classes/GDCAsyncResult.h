#import <Foundation/Foundation.h>
#import "GDCMessage.h"

@protocol GDCAsyncResult <NSObject>

@property(nonatomic, readonly) NSError *cause;
@property(nonatomic, readonly) BOOL failed;
@property(nonatomic, readonly) id <GDCMessage> result;

@end