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

- (id<GDCBus>)publish:(NSString *)address message:(id)msg {
  [delegate_ publishWithNSString:address withId:msg];
  return self;
}

- (id<GDCBus>)publishLocal:(NSString *)address message:(id)msg {
  [delegate_ publishLocalWithNSString:address withId:msg];
  return self;
}

- (id<GDCRegistration>)registerHandler:(NSString *)address handler:(GDCMessageHandler)handler {
  return (id<GDCRegistration>)[delegate_ registerHandlerWithNSString:address withComGoodowRealtimeCoreHandler:handler];
}

- (id<GDCRegistration>)registerLocalHandler:(NSString *)address handler:(GDCMessageHandler)handler {
  return (id<GDCRegistration>)[delegate_ registerLocalHandlerWithNSString:address withComGoodowRealtimeCoreHandler:handler];;
}

- (id<GDCBus>)send:(NSString *)address message:(id)msg replyHandler:(GDCMessageHandler)replyHandler {
  [delegate_ sendWithNSString:address withId:msg withComGoodowRealtimeCoreHandler:replyHandler];
  return self;
}

- (id<GDCBus>)sendLocal:(NSString *)address message:(id)msg replyHandler:(GDCMessageHandler)replyHandler {
  [delegate_ sendLocalWithNSString:address withId:msg withComGoodowRealtimeCoreHandler:replyHandler];
  return self;
}

@end