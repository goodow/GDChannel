//
//  GDCEventBusTests.m
//  GDChannel
//
//  Created by Larry Tin.
//  Copyright (c) 2013年 Goodow. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GDChannel.h"

@interface GDCEventBusTests : XCTestCase

@end

@implementation GDCEventBusTests

- (void)setUp
{
  [super setUp];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testExample
{
  id<GDCBus> bus = [[GDCReconnectBus alloc] initWithUrl:@"ws://realtime.goodow.com:1986/channel/websocket" options:@{@"forkLocal":@YES}];
  __block id<GDCHandlerRegistration> handlerRegistration;
  __block BOOL testComplete = NO;
  
  [bus registerLocalHandler:GDCBus_get_ON_OPEN_() handler:^(id<GDCMessage> message) {
    NSLog(@"%@", @"EventBus opend");
  }];
  [bus registerLocalHandler:GDCBus_get_ON_CLOSE_() handler:^(id<GDCMessage> message) {
    NSLog(@"%@", @"EventBus closed");
    testComplete = YES;
  }];
  [bus registerLocalHandler:GDCBus_get_ON_ERROR_() handler:^(id<GDCMessage> message) {
    NSLog(@"%@", @"EventBus Error");
  }];
  
  handlerRegistration = [bus registerHandler:@"objc.someaddress" handler:^(id<GDCMessage> message) {
    NSMutableDictionary *body = [message body];
    XCTAssertTrue([@"send1" isEqualToString:[body objectForKey:@"text"]]);
    
    NSDictionary *msg = @{@"text": @"reply1"};
    [message reply:msg replyHandler:^(id<GDCMessage> message) {
      NSMutableDictionary *body = [message body];
      XCTAssertTrue([@"reply2" isEqualToString:[body objectForKey:@"text"]]);
      
      [handlerRegistration unregisterHandler];
      handlerRegistration = nil;
      [bus close];
    }];
  }];
  
  [bus send:@"objc.someaddress" message:@{@"text": @"send1"} replyHandler:^(id<GDCMessage> message) {
    NSMutableDictionary *body = [message body];
    XCTAssertTrue([@"reply1" isEqualToString:[body objectForKey:@"text"]]);
    
    [message reply:@{@"text": @"reply2"}];
  }];
  
  // Begin a run loop terminated when the testComplete it set to true
  while (!testComplete && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]);
}

@end
