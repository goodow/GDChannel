#import <Foundation/Foundation.h>

@protocol GDCMessage;

@protocol GDCAsyncResult <NSObject>

- (NSError *)cause;

- (BOOL)failed;

- (id<GDCMessage>)result;

@end