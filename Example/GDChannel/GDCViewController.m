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
#import "GDCSampleEntry.h"
#import "GDCViewOptions.h"

@interface GDCViewController ()

@end

@implementation GDCViewController {
  id <GDCMessageConsumer> consumer;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
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
        id <GDCMessage> o = [storage get:message.topic];
        GDCSampleEntry *entry = [GDCSampleEntry of:message.payload];
        GDCOptions *options = [GDCViewOptions options];
        options.extras = @{@"optRe" : @YES};
        [message reply:@"re" options:options replyHandler:^(id <GDCAsyncResult> asyncResult) {
            id <GDCMessage> result = asyncResult.result;
            NSLog(@"asyncResult2: %@", result);
        }];
    }];
  }
}

- (IBAction)publish:(UIButton *)sender {
  GDCSampleEntry *entry = [[GDCSampleEntry alloc] init];
  entry.floatA = 2.1;
  entry.str = @"testEntry";
  GDCSampleEntry *subEntry = [[GDCSampleEntry alloc] init];
  subEntry.floatA = -1.1;
  entry.entry = subEntry;
  GDCOptions *options = [GDCViewOptions options];
  options.retained = YES;
  [self.bus send:@"sometopic1" payload:entry options:options replyHandler:^(id <GDCAsyncResult> asyncResult) {
      id <GDCMessage> o = asyncResult.result;
      NSLog(@"asyncResult: %@", o);
      [o reply:@"re2"];
  }];
}

- (IBAction)unsubscribe:(id)sender {
  [consumer unsubscribe];
  consumer = nil;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
