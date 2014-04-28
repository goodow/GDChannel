//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/channel/impl/WebSocketBus.java
//
//  Created by retechretech.
//

#ifndef _GDCWebSocketBus_H_
#define _GDCWebSocketBus_H_

@class JavaLangVoid;
@class JavaUtilLoggingLogger;
@protocol ComGoodowRealtimeCoreWebSocket;
@protocol GDCMessage;
@protocol GDJsonObject;

#import "JreEmulation.h"
#include "com/goodow/realtime/channel/impl/SimpleBus.h"
#include "com/goodow/realtime/core/Handler.h"
#include "com/goodow/realtime/core/WebSocket.h"

@interface GDCWebSocketBus : GDCSimpleBus {
 @public
  id<ComGoodowRealtimeCoreWebSocket> webSocket_;
  NSString *url_;
  id<ComGoodowRealtimeCoreWebSocket_WebSocketHandler> webSocketHandler_;
  int pingInterval_;
  NSString *sessionID_;
  int pingTimerID_;
}

- (id)initWithNSString:(NSString *)url
      withGDJsonObject:(id<GDJsonObject>)options;

- (void)connectWithNSString:(NSString *)url
           withGDJsonObject:(id<GDJsonObject>)options;

- (void)login:(NSString *)username password:(NSString *)password replyHandler:(id)replyHandler;

- (void)doClose;

- (BOOL)doRegisterHandlerWithNSString:(NSString *)address
     withComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)handler;

- (void)doSendOrPubWithBoolean:(BOOL)send
                  withNSString:(NSString *)address
                        withId:(id)msg
withComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)replyHandler;

- (BOOL)doUnregisterHandlerWithNSString:(NSString *)address
       withComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)handler;

- (void)sendWithNSString:(NSString *)msg;

- (void)sendPing;

- (void)sendRegisterWithNSString:(NSString *)address;

- (void)sendUnregisterWithNSString:(NSString *)address;

- (void)copyAllFieldsTo:(GDCWebSocketBus *)other;

@end

FOUNDATION_EXPORT BOOL GDCWebSocketBus_initialized;
J2OBJC_STATIC_INIT(GDCWebSocketBus)

J2OBJC_FIELD_SETTER(GDCWebSocketBus, webSocket_, id<ComGoodowRealtimeCoreWebSocket>)
J2OBJC_FIELD_SETTER(GDCWebSocketBus, url_, NSString *)
J2OBJC_FIELD_SETTER(GDCWebSocketBus, webSocketHandler_, id<ComGoodowRealtimeCoreWebSocket_WebSocketHandler>)
J2OBJC_FIELD_SETTER(GDCWebSocketBus, sessionID_, NSString *)

FOUNDATION_EXPORT NSString *GDCWebSocketBus_PING_INTERVAL_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, PING_INTERVAL_, NSString *)

FOUNDATION_EXPORT NSString *GDCWebSocketBus_BODY_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, BODY_, NSString *)

FOUNDATION_EXPORT NSString *GDCWebSocketBus_ADDRESS_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, ADDRESS_, NSString *)

FOUNDATION_EXPORT NSString *GDCWebSocketBus_REPLY_ADDRESS_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, REPLY_ADDRESS_, NSString *)

FOUNDATION_EXPORT NSString *GDCWebSocketBus_TYPE_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, TYPE_, NSString *)

FOUNDATION_EXPORT JavaUtilLoggingLogger *GDCWebSocketBus_log_WebSocketBus_;
J2OBJC_STATIC_FIELD_GETTER(GDCWebSocketBus, log_WebSocketBus_, JavaUtilLoggingLogger *)

typedef GDCWebSocketBus ComGoodowRealtimeChannelImplWebSocketBus;

@interface GDCWebSocketBus_$1 : NSObject < ComGoodowRealtimeCoreWebSocket_WebSocketHandler > {
 @public
  GDCWebSocketBus *this$0_;
}

- (void)onCloseWithGDJsonObject:(id<GDJsonObject>)reason;

- (void)onErrorWithNSString:(NSString *)error;

- (void)onMessageWithNSString:(NSString *)msg;

- (void)onOpen;

- (id)initWithGDCWebSocketBus:(GDCWebSocketBus *)outer$;

@end

__attribute__((always_inline)) inline void GDCWebSocketBus_$1_init() {}

J2OBJC_FIELD_SETTER(GDCWebSocketBus_$1, this$0_, GDCWebSocketBus *)

@interface GDCWebSocketBus_$1_$1 : NSObject < ComGoodowRealtimeCoreHandler > {
 @public
  GDCWebSocketBus_$1 *this$0_;
}

- (void)handleWithId:(id)ignore;

- (id)initWithGDCWebSocketBus_$1:(GDCWebSocketBus_$1 *)outer$;

@end

__attribute__((always_inline)) inline void GDCWebSocketBus_$1_$1_init() {}

J2OBJC_FIELD_SETTER(GDCWebSocketBus_$1_$1, this$0_, GDCWebSocketBus_$1 *)

@interface GDCWebSocketBus_$2 : NSObject < ComGoodowRealtimeCoreHandler > {
 @public
  GDCWebSocketBus *this$0_;
  id<ComGoodowRealtimeCoreHandler> val$replyHandler_;
}

- (void)handleWithId:(id<GDCMessage>)msg;

- (id)initWithGDCWebSocketBus:(GDCWebSocketBus *)outer$
withComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)capture$0;

@end

__attribute__((always_inline)) inline void GDCWebSocketBus_$2_init() {}

J2OBJC_FIELD_SETTER(GDCWebSocketBus_$2, this$0_, GDCWebSocketBus *)
J2OBJC_FIELD_SETTER(GDCWebSocketBus_$2, val$replyHandler_, id<ComGoodowRealtimeCoreHandler>)

@interface GDCWebSocketBus_$3 : NSObject < ComGoodowRealtimeCoreHandler > {
 @public
  GDCWebSocketBus *this$0_;
}

- (void)handleWithId:(id<GDCMessage>)event;

- (id)initWithGDCWebSocketBus:(GDCWebSocketBus *)outer$;

@end

__attribute__((always_inline)) inline void GDCWebSocketBus_$3_init() {}

J2OBJC_FIELD_SETTER(GDCWebSocketBus_$3, this$0_, GDCWebSocketBus *)

#endif // _GDCWebSocketBus_H_