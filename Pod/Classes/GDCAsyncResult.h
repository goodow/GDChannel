#import <Foundation/Foundation.h>

@protocol GDCMessage;

@protocol GDCAsyncResult <NSObject>

@property(nonatomic, readonly) NSError *cause;
@property(nonatomic, readonly) BOOL failed;
@property(nonatomic, readonly) id <GDCMessage> result;

@end