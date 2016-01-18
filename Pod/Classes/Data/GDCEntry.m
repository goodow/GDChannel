//
// Created by Larry Tin on 15/12/8.
// Copyright (c) 2015 Larry Tin. All rights reserved.
//

#import <objc/runtime.h>
#import "GDCEntry.h"
#import "MTLJSONAdapter.h"
#import "NSDictionary+MTLMappingAdditions.h"
#import "NSObject+GDChannel.h"
#import "GDCNotificationBus.h"
#import "MTLModel+NSCoding.h"

@interface GDCEntry () <MTLJSONSerializing>
@end

@implementation GDCEntry {
  NSMutableDictionary *_topics;
  BOOL _scheduled;
}
- (instancetype)init {
  self = [super init];
  if (self) {
    _topics = [NSMutableDictionary dictionary];
    [self addOrRemoveObserverForEntry:self.class parentKey:nil isAdd:YES];
  }

  return self;
}

- (void)dealloc {
  [self addOrRemoveObserverForEntry:self.class parentKey:nil isAdd:NO];
}

- (void)addOrRemoveObserverForEntry:(Class)entry parentKey:(NSString *)parentKey isAdd:(BOOL)isAdd {
  NSDictionary *classesByPropertyKey = [entry allowedSecureCodingClassesByPropertyKey];
  for (NSString *key in classesByPropertyKey) {
    NSString *keyPath = parentKey ? [NSString stringWithFormat:@"%@.%@", parentKey, key] : key;
    if (isAdd) {
      [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    } else {
      [self removeObserver:self forKeyPath:keyPath];
    }
    if ([classesByPropertyKey[key] count] == 1) {
      Class clz = classesByPropertyKey[key][0];
      if ([clz conformsToProtocol:@protocol(GDCEntry)]) {
        [self addOrRemoveObserverForEntry:clz parentKey:keyPath isAdd:isAdd];
      }
    }
  }
}

+ (instancetype)of:(id)payload {
  if (!payload || [payload isKindOfClass:self]) {
    return payload;
  }
  if (![self conformsToProtocol:@protocol(GDCEntry)]) {
    return nil;
  }
  NSDictionary *dict = [payload isKindOfClass:NSDictionary.class] ? payload : [payload toDictionary];
  NSError *error = nil;
  GDCEntry *toRtn = [MTLJSONAdapter modelOfClass:self fromJSONDictionary:dict error:&error];
  if (error) {
    NSLog(@"[%s] Error creating entry: %@", __PRETTY_FUNCTION__, error);
  }
  return toRtn;
}

- (NSDictionary *)toDictionary {
  NSError *error = nil;
  NSDictionary *toRtn = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
  if (error) {
    NSLog(@"[%s] Error serializing entry: %@", __PRETTY_FUNCTION__, error);
  }
  return toRtn;
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  __weak GDCEntry *weak = self;
  if (_scheduled || _topics.count == 0 || [change[NSKeyValueChangeOldKey] isEqual:change[NSKeyValueChangeNewKey]]) {
    return;
  }
  _scheduled = YES;
  NSDictionary *topics = [_topics copy];
  [GDCNotificationBus scheduleDeferred:^(id o) {
      for (NSString *topic in topics) {
//        [keyPath description];
        [weak.bus publishLocal:topic payload:weak options:topics[topic] == [NSNull null] ? nil : topics[topic]];
      }
      _scheduled = NO;
  } argument:nil];
}

- (void)addTopic:(NSString *)topic options:(GDCOptions *)options {
  _topics[topic] = options ?: [NSNull null];
}
@end