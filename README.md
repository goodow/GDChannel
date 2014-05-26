GDChannel [![Build Status](https://travis-ci.org/goodow/GDChannel.svg?branch=master)](https://travis-ci.org/goodow/GDChannel)
=========
Event bus client over WebSocket for iOS and OS X

## Adding GDChannel to your project

### Cocoapods

[CocoaPods](http://cocoapods.org) is the recommended way to add GDChannel to your project.

1. Add these pods to your Podfile:
```ruby
pod 'J2ObjC', :git => 'https://github.com/goodow/j2objc.git'
pod 'GDJson', :git => 'https://github.com/goodow/GDJson.git'
pod 'GDChannel', :git => 'https://github.com/goodow/GDChannel.git'
```
2. Install the pod(s) by running `pod install`.
3. Include GDChannel wherever you need it with `#import "GDChannel.h"`.

## Usage

### WebSocket mode
See https://github.com/goodow/GDChannel/blob/master/Project/GDChannelTests/GDCWebSocketBusTests.m

### Local mode
See https://github.com/goodow/GDChannel/blob/master/Project/GDChannelTests/GDCSimpleBusTests.m
