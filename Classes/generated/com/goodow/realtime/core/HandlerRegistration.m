//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/core/HandlerRegistration.java
//
//  Created by retechretech.
//

#include "com/goodow/realtime/core/HandlerRegistration.h"

BOOL ComGoodowRealtimeCoreHandlerRegistration_initialized = NO;

id<ComGoodowRealtimeCoreHandlerRegistration> ComGoodowRealtimeCoreHandlerRegistration_EMPTY_;

@implementation ComGoodowRealtimeCoreHandlerRegistration

+ (void)initialize {
  if (self == [ComGoodowRealtimeCoreHandlerRegistration class]) {
    ComGoodowRealtimeCoreHandlerRegistration_EMPTY_ = [[ComGoodowRealtimeCoreHandlerRegistration_$1 alloc] init];
    ComGoodowRealtimeCoreHandlerRegistration_initialized = YES;
  }
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "unregisterHandler", NULL, "V", 0x401, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "EMPTY_", NULL, 0x19, "Lcom.goodow.realtime.core.HandlerRegistration;", &ComGoodowRealtimeCoreHandlerRegistration_EMPTY_,  },
  };
  static J2ObjcClassInfo _ComGoodowRealtimeCoreHandlerRegistration = { "HandlerRegistration", "com.goodow.realtime.core", NULL, 0x201, 1, methods, 1, fields, 0, NULL};
  return &_ComGoodowRealtimeCoreHandlerRegistration;
}

@end

@implementation ComGoodowRealtimeCoreHandlerRegistration_$1

- (void)unregisterHandler {
}

- (id)init {
  return [super init];
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "unregisterHandler", NULL, "V", 0x1, NULL },
    { "init", NULL, NULL, 0x0, NULL },
  };
  static J2ObjcClassInfo _ComGoodowRealtimeCoreHandlerRegistration_$1 = { "$1", "com.goodow.realtime.core", "HandlerRegistration", 0x8000, 2, methods, 0, NULL, 0, NULL};
  return &_ComGoodowRealtimeCoreHandlerRegistration_$1;
}

@end
