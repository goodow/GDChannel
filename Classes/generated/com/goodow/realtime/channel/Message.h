//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/channel/Message.java
//
//  Created by retechretech.
//

#ifndef _GDCMessage_H_
#define _GDCMessage_H_

@protocol ComGoodowRealtimeCoreHandler;

#import "JreEmulation.h"

@protocol GDCMessage < NSObject, JavaObject >

- (NSString *)address;

- (id)body;

- (void)fail:(int)failureCode message:(NSString *)msg;

- (void)reply:(id)msg;

- (void)reply:(id)msg replyHandler:(id)replyHandler;

- (NSString *)replyAddress;

@end

__attribute__((always_inline)) inline void GDCMessage_init() {}

#define ComGoodowRealtimeChannelMessage GDCMessage

#endif // _GDCMessage_H_
