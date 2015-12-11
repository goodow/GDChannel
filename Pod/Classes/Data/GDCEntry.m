//
// Created by Larry Tin on 15/12/8.
// Copyright (c) 2015 Larry Tin. All rights reserved.
//

#import "GDCEntry.h"
#import "MTLJSONAdapter.h"
#import "NSDictionary+MTLMappingAdditions.h"
#import "NSObject+GDChannel.h"

@interface GDCEntry () <MTLJSONSerializing>
@end

@implementation GDCEntry {
  NSMutableSet *_topics;
}
- (instancetype)init {
  self = [super init];
  if (self) {
    _topics = [NSMutableSet set];
    for (NSString *key in self.class.propertyKeys) {
      [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:nil];
    }
  }

  return self;
}

- (void)dealloc {
  for (NSString *key in self.class.propertyKeys) {
    [self removeObserver:self forKeyPath:key];
  }
}

+ (instancetype)of:(id)payload {
  if ([payload isKindOfClass:self]) {
    return payload;
  }
  if (![self conformsToProtocol:@protocol(GDCEntry)]) {
    return nil;
  }
  NSDictionary *dict = [payload isKindOfClass:NSDictionary.class] ? payload : [payload toDictionary];
  NSError *error = nil;
  return [MTLJSONAdapter modelOfClass:self fromJSONDictionary:dict error:&error];
}

- (NSDictionary *)toDictionary {
  NSError *error = nil;
  return [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
}


+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return [NSDictionary mtl_identityPropertyMapWithModel:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

  for (NSString *topic in _topics) {
    [self.bus publishLocal:topic payload:self options:nil];
  }
}

- (void)addTopic:(NSString *)topic {
  [_topics addObject:topic];
}
@end