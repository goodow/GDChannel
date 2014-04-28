//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/core/impl/DefaultFutureResult.java
//
//  Created by retechretech.
//

#ifndef _ComGoodowRealtimeCoreImplDefaultFutureResult_H_
#define _ComGoodowRealtimeCoreImplDefaultFutureResult_H_

@class JavaLangThrowable;
@protocol ComGoodowRealtimeCoreHandler;

#import "JreEmulation.h"
#include "com/goodow/realtime/core/Future.h"

@interface ComGoodowRealtimeCoreImplDefaultFutureResult : NSObject < ComGoodowRealtimeCoreFuture > {
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

- (ComGoodowRealtimeCoreImplDefaultFutureResult *)setFailureWithJavaLangThrowable:(JavaLangThrowable *)throwable;

- (ComGoodowRealtimeCoreImplDefaultFutureResult *)setHandlerWithComGoodowRealtimeCoreHandler:(id<ComGoodowRealtimeCoreHandler>)handler;

- (ComGoodowRealtimeCoreImplDefaultFutureResult *)setResultWithId:(id)result;

- (BOOL)succeeded;

- (void)checkCallHandler;

- (void)copyAllFieldsTo:(ComGoodowRealtimeCoreImplDefaultFutureResult *)other;

@end

__attribute__((always_inline)) inline void ComGoodowRealtimeCoreImplDefaultFutureResult_init() {}

J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplDefaultFutureResult, handler_, id<ComGoodowRealtimeCoreHandler>)
J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplDefaultFutureResult, result__, id)
J2OBJC_FIELD_SETTER(ComGoodowRealtimeCoreImplDefaultFutureResult, throwable_, JavaLangThrowable *)

#endif // _ComGoodowRealtimeCoreImplDefaultFutureResult_H_
