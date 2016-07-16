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
#import "GDCStorage.h"
#import "MTLTransformerErrorHandling.h"
#import "NSDictionary+MTLJSONKeyPath.h"

@interface MTLJSONAdapter (MergeFromDictionary)
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;
@end

@interface GDCEntry () <MTLJSONSerializing>
@end

@implementation GDCEntry {
  NSMutableDictionary *_topics;
  BOOL _scheduled;
  BOOL _inhibitNotify;
  NSMutableDictionary *_changes;
}
- (instancetype)init {
  self = [super init];
  if (self) {
    _topics = [NSMutableDictionary dictionary];
    _changes = [NSMutableDictionary dictionary];
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

+ (instancetype)parseFromJson:(nullable NSDictionary *)json error:(NSError **)errorPtr {
  if (!json || [json isKindOfClass:self]) {
    return json;
  }
  if (![self conformsToProtocol:@protocol(GDCEntry)]) {
    return nil;
  }
  NSError *error = nil;
  GDCEntry *toRtn = [MTLJSONAdapter modelOfClass:self fromJSONDictionary:json error:&error];
  if (error) {
    NSLog(@"[%s] Error creating entry: %@", __PRETTY_FUNCTION__, error);
  }
  return toRtn;
}

- (NSDictionary *)toJson {
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
  _changes[keyPath] = change[NSKeyValueChangeNewKey];
  NSDictionary *topics = [_topics copy];
  BOOL inhibitNotify = _inhibitNotify;
  [GDCNotificationBus scheduleDeferred:^(id o) {
      NSMutableDictionary *changes = _changes.copy;
      [_changes removeAllObjects];
      for (NSString *topic in topics) {
//        [keyPath description];
        if (!inhibitNotify) {
          [weak.bus publishLocal:topic payload:weak options:topics[topic] == [NSNull null] ? nil : topics[topic]];
        }
        [weak.bus publishLocal:[topic stringByAppendingPathComponent:watchChanges] payload:changes];
      }
      _scheduled = NO;
  } argument:nil];
}

- (void)addTopic:(NSString *)topic options:(GDCOptions *)options {
  _topics[topic] = options ?: [NSNull null];
}

- (void)mergeFromJson:(NSDictionary *)json {
  _inhibitNotify = YES;
  NSMutableDictionary *expandedPatch = [NSMutableDictionary dictionary];
  [GDCStorage expandDictionary:json to:expandedPatch];
  [self.class patchEntry:self withDictionary:expandedPatch];
  _inhibitNotify = NO;
}

- (void)mergeFrom:(GDCEntry *)other {
  _inhibitNotify = YES;
  [self mergeValuesForKeysFromModel:other];
  _inhibitNotify = NO;
}

+ (void)patchEntry:(NSObject <MTLModel, MTLJSONSerializing> *)original withDictionary:(NSDictionary *)patch {
  NSError *error;
  Class modelClass = original.class;
  NSDictionary *keyPathsByPropertyKey = [modelClass JSONKeyPathsByPropertyKey];
  NSDictionary *valueTransformersByPropertyKey = [MTLJSONAdapter valueTransformersForModelClass:modelClass];
  for (NSString *propertyKey in [modelClass propertyKeys]) {
    id keyPaths = keyPathsByPropertyKey[propertyKey];
    if (keyPaths == nil) {
      continue;
    }

    id value;
    if ([keyPaths isKindOfClass:NSArray.class]) {
      NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
      for (NSString *keyPath in keyPaths) {
        BOOL success = NO;
        id value = [patch mtl_valueForJSONKeyPath:keyPath success:&success error:&error];
        if (!success) {
          continue;
        }
        if (value != nil) {
          dictionary[keyPath] = value;
        }
      }
      value = dictionary;
    } else {
      BOOL success = NO;
      value = [patch mtl_valueForJSONKeyPath:keyPaths success:&success error:&error];
      if (!success) {
        continue;
      }
    }
    if (value == nil) {
      continue;
    }
    id originalVal = [original valueForKey:propertyKey];
    if ([originalVal conformsToProtocol:@protocol(GDCEntry)]) {
      [self patchEntry:originalVal withDictionary:value];
      continue;
    }

    @try {
      NSValueTransformer *transformer = valueTransformersByPropertyKey[propertyKey];
      if (transformer != nil) {
        // Map NSNull -> nil for the transformer, and then back for the
        // dictionary we're going to insert into.
        if ([value isEqual:NSNull.null]) {
          value = nil;
        }

        if ([transformer respondsToSelector:@selector(transformedValue:success:error:)]) {
          id <MTLTransformerErrorHandling> errorHandlingTransformer = (id) transformer;

          BOOL success = YES;
          value = [errorHandlingTransformer transformedValue:value success:&success error:&error];

          if (!success) {
            continue;
          }
        } else {
          value = [transformer transformedValue:value];
        }
        if (value == nil) {
          value = NSNull.null;
        }
      }

      [original setValue:value forKey:propertyKey];
    } @catch (NSException *ex) {
      NSLog(@"*** Caught exception %@ parsing JSON key path \"%@\" from: %@", ex, keyPaths, patch);

      // Fail fast in Debug builds.
#if DEBUG
      @throw ex;
#else
      if (error != NULL) {
        NSDictionary *userInfo = @{
          NSLocalizedDescriptionKey: ex.description,
          NSLocalizedFailureReasonErrorKey: ex.reason,
          MTLJSONAdapterThrownExceptionErrorKey: ex
        };

        error = [NSError errorWithDomain:MTLJSONAdapterErrorDomain code:MTLJSONAdapterErrorExceptionThrown userInfo:userInfo];
      }

      return;
#endif
    }
  }
}

@end