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
//  GDCBus.h
//  GDChannel
//
//  Created by Larry Tin.
//

@protocol GDCMessage;
@protocol GDCRegistration;

#define GDCBus_ON_OPEN @"@realtime.bus.onOpen"
#define GDCBus_ON_CLOSE @"@realtime.bus.onClose"
#define GDCBus_ON_ERROR @"@realtime.bus.onError"

typedef void (^GDCMessageHandler)(id<GDCMessage> message);
typedef enum {
  GDC_CONNECTING   = 0,
  GDC_OPEN         = 1,
  GDC_CLOSING      = 2,
  GDC_CLOSED       = 3,
} GDCState;

@protocol GDCBus

- (void)close;

- (GDCState)getReadyState;

- (id<GDCBus>)publish:(NSString *)address message:(id)msg;

- (id<GDCBus>)publishLocal:(NSString *)address message:(id)msg;

- (id<GDCRegistration>)registerHandler:(NSString *)address handler:(GDCMessageHandler)handler;

- (id<GDCRegistration>)registerLocalHandler:(NSString *)address handler:(GDCMessageHandler)handler;

- (id<GDCBus>)send:(NSString *)address message:(id)msg replyHandler:(GDCMessageHandler)replyHandler;

- (id<GDCBus>)sendLocal:(NSString *)address message:(id)msg replyHandler:(GDCMessageHandler)replyHandler;

@end
