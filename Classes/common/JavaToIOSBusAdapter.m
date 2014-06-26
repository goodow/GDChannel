// Copyright 2014 Goodow.com. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  JavaToIOSBusAdapter.m
//  GDChannel
//
//  Created by Larry Tin.
//

#import "JavaToIOSBusAdapter.h"
#import "com/goodow/realtime/channel/Bus.h"
#import "com/goodow/realtime/channel/State.h"

@implementation JavaToIOSBusAdapter

-(id)initWithJavaBus:(id<ComGoodowRealtimeChannelBus>)bus {
  if ((self = [super init])) {
    delegate_ = bus;
  }
  return self;
}

+(JavaToIOSBusAdapter *)fromJavaBus:(id<ComGoodowRealtimeChannelBus>)bus {
  return [[JavaToIOSBusAdapter alloc] initWithJavaBus:bus];
}

- (void)close {
  [delegate_ close];
}

- (GDCState)getReadyState {
  return [[delegate_ getReadyState] ordinal];
}

- (NSString *)getSessionId {
  return [delegate_ getSessionId];
}

- (id<GDCBus>)publish:(NSString *)topic message:(id)msg {
  [delegate_ publishWithNSString:topic withId:msg];
  return self;
}

- (id<GDCBus>)publishLocal:(NSString *)topic message:(id)msg {
  [delegate_ publishLocalWithNSString:topic withId:msg];
  return self;
}

- (id<GDCRegistration>)subscribe:(NSString *)topic handler:(GDCMessageHandler)handler {
  return (id<GDCRegistration>) [delegate_ subscribeWithNSString:topic withComGoodowRealtimeCoreHandler:handler];
}

- (id<GDCRegistration>)subscribeLocal:(NSString *)topic handler:(GDCMessageHandler)handler {
  return (id<GDCRegistration>) [delegate_ subscribeLocalWithNSString:topic withComGoodowRealtimeCoreHandler:handler];;
}

- (id<GDCBus>)send:(NSString *)topic message:(id)msg replyHandler:(GDCMessageHandler)replyHandler {
  [delegate_ sendWithNSString:topic withId:msg withComGoodowRealtimeCoreHandler:replyHandler];
  return self;
}

- (id<GDCBus>)sendLocal:(NSString *)topic message:(id)msg replyHandler:(GDCMessageHandler)replyHandler {
  [delegate_ sendLocalWithNSString:topic withId:msg withComGoodowRealtimeCoreHandler:replyHandler];
  return self;
}

@end