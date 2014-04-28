//
//  Generated by the J2ObjC translator.  DO NOT EDIT!
//  source: /Users/retechretech/dev/workspace/realtime/realtime-channel/src/main/java/com/goodow/realtime/channel/ReplyException.java
//
//  Created by retechretech.
//

#include "com/goodow/realtime/channel/ReplyException.h"
#include "com/goodow/realtime/channel/ReplyFailure.h"

@implementation GDCReplyException

- (id)initWithGDCReplyFailureEnum:(GDCReplyFailureEnum *)failureType {
  if (self = [super initWithNSString:(NSString *) check_class_cast(nil, [NSString class])]) {
    self->failureType__ = failureType;
    self->failureCode__ = -1;
  }
  return self;
}

- (id)initWithGDCReplyFailureEnum:(GDCReplyFailureEnum *)failureType
                          withInt:(int)failureCode
                     withNSString:(NSString *)message {
  if (self = [super initWithNSString:message]) {
    self->failureType__ = failureType;
    self->failureCode__ = failureCode;
  }
  return self;
}

- (id)initWithGDCReplyFailureEnum:(GDCReplyFailureEnum *)failureType
                     withNSString:(NSString *)message {
  if (self = [super initWithNSString:message]) {
    self->failureType__ = failureType;
    self->failureCode__ = -1;
  }
  return self;
}

- (int)failureCode {
  return failureCode__;
}

- (GDCReplyFailureEnum *)failureType {
  return failureType__;
}

- (void)copyAllFieldsTo:(GDCReplyException *)other {
  [super copyAllFieldsTo:other];
  other->failureCode__ = failureCode__;
  other->failureType__ = failureType__;
}

+ (J2ObjcClassInfo *)__metadata {
  static J2ObjcMethodInfo methods[] = {
    { "initWithGDCReplyFailureEnum:", "ReplyException", NULL, 0x1, NULL },
    { "initWithGDCReplyFailureEnum:withInt:withNSString:", "ReplyException", NULL, 0x1, NULL },
    { "initWithGDCReplyFailureEnum:withNSString:", "ReplyException", NULL, 0x1, NULL },
    { "failureCode", NULL, "I", 0x1, NULL },
    { "failureType", NULL, "Lcom.goodow.realtime.channel.ReplyFailure;", 0x1, NULL },
  };
  static J2ObjcFieldInfo fields[] = {
    { "serialVersionUID_ReplyException_", "serialVersionUID", 0x1a, "J", NULL, .constantValue.asLong = GDCReplyException_serialVersionUID },
    { "failureType__", "failureType", 0x12, "Lcom.goodow.realtime.channel.ReplyFailure;", NULL,  },
    { "failureCode__", "failureCode", 0x12, "I", NULL,  },
  };
  static J2ObjcClassInfo _GDCReplyException = { "ReplyException", "com.goodow.realtime.channel", NULL, 0x1, 5, methods, 3, fields, 0, NULL};
  return &_GDCReplyException;
}

@end