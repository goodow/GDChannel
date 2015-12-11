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
#import "GDCTestEntry.h"

@interface GDCViewController ()

@end

@implementation GDCViewController {
  id <GDCMessageConsumer> consumer;
  GDCSampleEntry *_entry;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSLog(@"viewWillAppear");

  GDCSampleEntry *entry = [[GDCSampleEntry alloc] init];
  entry.str = @"entryS";
  entry.str = nil;
  entry.str = nil;
  entry.str = @"";
  GDCOptions *options = [[GDCOptions alloc] init];
  options.extras = @{@"optRe" : @YES};
  options.retained = YES;
//  [entry addTopic:@"top" options:options];
  GDCSampleEntry *subEntry = [[GDCSampleEntry alloc] init];
  subEntry.str = @"subS";
//  entry.entry = subEntry;
  subEntry.str = @"subS22";
//  entry.str = @"entryS22";
  GDCTestEntry *testEntry = [[GDCTestEntry alloc] init];
  testEntry.entryList = @[entry, subEntry];
  [self.bus publishLocal:@"chao" payload:testEntry options:options];
  NSDictionary *a = testEntry.toDictionary;
}

- (IBAction)subscribe:(UIButton *)sender {
  if (!consumer) {
    consumer = [self.bus subscribe:@"sometopic1" handler:^(id <GDCMessage> message) {
        NSLog(@"test: %@", message);
        GDCStorage *storage = [[GDCStorage alloc] initWithBaseDirectory:nil];
        id o = [storage getPayload:message.topic];
        GDCSampleEntry *entry = [GDCSampleEntry of:message.payload];
        GDCOptions *options = [GDCOptions createWithViewOptions];
        options.extras = @{@"optRe" : @YES};
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

  o.options;
  if (_entry) {
    _entry.floatA++;
    return;
  }
  _entry = [[GDCSampleEntry alloc] init];
  _entry.floatA = 2.1;
  _entry.str = @"testEntry";
  GDCSampleEntry *subEntry = [[GDCSampleEntry alloc] init];
  subEntry.floatA = -1.1;
//  _entry.entry = subEntry;
  GDCOptions *options = [GDCOptions createWithViewOptions];
  options.retained = YES;
  [self.bus publishLocal:@"sometopic1" payload:_entry options:options];
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

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
