//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/core/impl/FutureResultImpl.java
//
//  Created by retechretech.
//

#ifndef _ComGoodowRealtimeCoreImplFutureResultImpl_H_
#define _ComGoodowRealtimeCoreImplFutureResultImpl_H_

@class JavaLangThrowable;
@protocol ComGoodowRealtimeCoreHandler;

#import "JreEmulation.h"
#include "com/goodow/realtime/core/Future.h"

@interface ComGoodowRealtimeCoreImplFutureResultImpl : NSObject < ComGoodowRealtimeCoreFuture > {
 @public
  BOOL failed__;
  BOOL succeeded__;
  id<ComGoodowRealtimeCoreHandler> handler_;
  id result__;
  JavaLangThrowable *throwable_;
}

- (id)init;

- (id)initWithId:(id)result;

- (id)initWithJavaLangThrowable:(JavaLangThrowable *)t;

- (JavaLangThrowable *)cause;

- (BOOL)complete;

- (BOOL)failed;

- (id)result;

- (ComGoodowRealtimeCoreImplFutureResultImpl *)setFailureWithJavaLangThrowable:(JavaLangThrowable *)throwable;

- (ComGoodowRealtimeCoreImplFutureResultImpl *)setHandlerWithComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)handler;

- (ComGoodowRealtimeCoreImplFutureResultImpl *)setResultWithId:(id)result;

- (BOOL)succeeded;

- (void)checkCallHandler;

- (void)copyAllFieldsTo:(ComGoodowRealtimeCoreImplFutureResultImpl *)other;

@end

__attribute__((always_inline)) inline void ComGoodowRealtimeCoreImplFutureResultImpl_init() {}

J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplFutureResultImpl, handler_, id<ComGoodowRealtimeCoreHandler>)
J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplFutureResultImpl, result__, id)
J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplFutureResultImpl, throwable_, JavaLangThrowable *)

#endif // _ComGoodowRealtimeCoreImplFutureResultImpl_H_
