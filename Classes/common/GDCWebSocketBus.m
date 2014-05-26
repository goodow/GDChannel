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
//  GDCWebSocketBus.m
//  GDChannel
//
//  Created by Larry Tin.
//

#import "GDCWebSocketBus.h"
#import "com/goodow/realtime/channel/impl/WebSocketBus.h"
#import "com/goodow/realtime/json/JsonObject.h"
#import "GDJson.h"

@implementation GDCWebSocketBus

- (id)initWithUrl:(NSString *)url options:(NSDictionary *)options {
  self = [super initWithJavaBus:[[ComGoodowRealtimeChannelImplWebSocketBus alloc] initWithNSString:url withComGoodowRealtimeJsonJsonObject:options]];
  return self;
}

@end
