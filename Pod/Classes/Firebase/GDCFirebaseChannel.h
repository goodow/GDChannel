//
// Created by Larry Tin on 2017/6/11.
//

#import <Foundation/Foundation.h>

@protocol GDCMessage;

@interface GDCFirebaseChannel : NSObject
- (instancetype)initWithClientId:(NSString *)clientId;

- (void)goOnline:(id)clientInfo;

- (void)reportMessage:(id <GDCMessage>)message;
@end