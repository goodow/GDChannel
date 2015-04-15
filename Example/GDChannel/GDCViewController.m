//
//  GDCViewController.m
//  GDChannel
//
//  Created by Larry Tin on 03/16/2015.
//  Copyright (c) 2014 Larry Tin. All rights reserved.
//

#import "GDCViewController.h"
#import "GDCBusProvider.h"

@interface GDCViewController ()

@end

@implementation GDCViewController {
  id <GDCMessageConsumer> consumer;
  id <GDCBus> bus;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  bus = [GDCBusProvider instance];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSLog(@"viewWillAppear");
}

- (IBAction)subscribe:(UIButton *)sender {
  consumer = [bus subscribe:@"sometopic1" handler:^(id <GDCMessage> message) {
      NSLog(@"test: %@", message.payload);
      [message reply:@"re" replyHandler:^(id <GDCAsyncResult> asyncResult) {
          id <GDCMessage> o = asyncResult.result;
          NSLog(@"asyncResult2: %@", o.payload);
      }];
  }];
}

- (IBAction)publish:(UIButton *)sender {
  [bus send:@"sometopic1" payload:@[@88] replyHandler:^(id <GDCAsyncResult> asyncResult) {
      id <GDCMessage> o = asyncResult.result;
      NSLog(@"asyncResult: %@", o.payload);
      [o reply:@"re2"];
  }];
}

- (IBAction)unsubscribe:(id)sender {
  [consumer unsubscribe];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
  [consumer unsubscribe];
}

@end
