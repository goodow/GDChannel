GDChannel [![Build Status](https://travis-ci.org/goodow/GDChannel.svg?branch=master)](https://travis-ci.org/goodow/GDChannel)
=========
iOS and Mac OS X client for realtime-channel

Visit [Google groups](https://groups.google.com/forum/#!forum/goodow-realtime) for discussions and announcements.

## Adding GDChannel to your project

### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add GDChannel to your project.

1. Add these pods to your Podfile:
```ruby
pod 'J2ObjC', :git => 'https://github.com/goodow/j2objc.git', :tag => 'v0.9.2-lib'
pod 'GDJson', :git => 'https://github.com/goodow/GDJson.git'
pod 'GDChannel', :git => 'https://github.com/goodow/GDChannel.git'
```
2. Install the pod(s) by running `pod install`.
3. Include GDChannel wherever you need it with `#import "GDChannel.h"`.

## Usage

### WebSocket mode
```objc
id<GDCBus> bus = [[GDCReconnectWebSocketBus alloc]
    initWithServerUri:@"ws://localhost:1986/channel/websocket" options:nil];

[bus subscribe:@"some/topic" handler:^(id<GDCMessage> message) {
  NSDictionary *body = [message body];
  NSLog(@"Name: %@", body[@"name"]);
}];

[bus publish:@"some/topic" message:@{@"name": @"Larry Tin"}];
```
See a [full example](https://github.com/goodow/GDChannel/blob/master/Project/GDChannelTests/GDCWebSocketBusTests.m)
for more usage.

### Local mode
See https://github.com/goodow/GDChannel/blob/master/Project/GDChannelTests/GDCSimpleBusTests.m
