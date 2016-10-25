//
//  GDCViewController.m
//  GDChannel
//
//  Created by Larry Tin on 03/16/2015.
//  Copyright (c) 2014 Larry Tin. All rights reserved.
//

#import "GDCViewController.h"
#import "NSObject+GDChannel.h"
#import "GDCStorage.h"

@interface GDCViewController ()

@end

@implementation GDCViewController {
  id <GDCMessageConsumer> consumer;
  NSThread *thread;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      thread = [NSThread currentThread];
      [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
  });
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      thread = [NSThread currentThread];
      [self performSelector:@selector(test) onThread:thread withObject:nil waitUntilDone:NO modes:@[NSDefaultRunLoopMode]];
  });
}

- (id)test {
  return @"saa";
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSLog(@"viewWillAppear");
}

- (IBAction)subscribe:(UIButton *)sender {
  if (!consumer) {
    consumer = [self.bus subscribe:@"sometopic1" handler:^(id <GDCMessage> message) {
        NSLog(@"test: %@", message);
        GDCStorage *storage = [[GDCStorage alloc] initWithBaseDirectory:nil];
        id o = [storage getPayload:message.topic];
        GDCOptions *options = GDCOptions.new.extras(@{@"optRe": @YES});
        [message reply:@"re" options:options replyHandler:^(id <GDCAsyncResult> asyncResult) {
            id <GDCMessage> result = asyncResult.result;
            NSLog(@"asyncResult2: %@", result);
        }];
    }];
  }
}

- (IBAction)publish:(UIButton *)sender {
  GDCStorage *storage = GDCStorage.instance;
  id <GDCMessage> o = [storage getRetainedMessage:@"chao"];
  GDCOptions *options = GDCOptions.new.extras(@{@"testExtras" : @"xxx"});
  options.retained(YES).timeout(1);
  [self.bus publishLocal:@"sometopic1" payload:@{} options:options];
//  [self.bus send:@"sometopic1" payload:_entry options:options replyHandler:^(id <GDCAsyncResult> asyncResult) {
//      id <GDCMessage> o = asyncResult.result;
//      NSLog(@"asyncResult: %@", o);
//      [o reply:@"re2"];
//  }];
}

- (IBAction)unsubscribe:(id)sender {
  [consumer unsubscribe];
  consumer = nil;
}

@end
