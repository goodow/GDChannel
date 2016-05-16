//
// Created by Larry Tin on 15/12/8.
//

#import "GDCStorage.h"
#import "GDCMessage.h"
#import "MTLJSONAdapter.h"
#import "NSDictionary+MTLJSONKeyPath.h"
#import "MTLTransformerErrorHandling.h"

static NSString *const fileExtension = @"archive";

@interface MTLJSONAdapter (MergeFromDictionary)
+ (NSDictionary *)valueTransformersForModelClass:(Class)modelClass;

@end

@implementation GDCStorage {
  NSString *_baseDir;
  NSMapTable *_cache;
}

+ (GDCStorage *)instance {
  static GDCStorage *_instance = nil;

  @synchronized (self) {
    if (_instance == nil) {
      _instance = [[self alloc] initWithBaseDirectory:nil];
    }
  }

  return _instance;
}

- (instancetype)initWithBaseDirectory:(NSString *)baseDir {
  self = [super init];
  if (self) {
    _cache = [NSMapTable strongToWeakObjectsMapTable];

    if (baseDir) {
      _baseDir = baseDir;
    } else {
      NSString *dir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES)[0];
      _baseDir = [dir stringByAppendingPathComponent:@"com.goodow.realtime.channel"];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_baseDir]) {
      NSError *error = nil;
      if (![[NSFileManager defaultManager] createDirectoryAtPath:_baseDir
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&error]) {
        NSLog(@"[%s] Error creating directory: %@", __PRETTY_FUNCTION__, error);
      }
    }
  }

  return self;
}

- (void)cache:(NSString *)topic payload:(id)payload {
  [_cache setObject:payload forKey:topic];
}

- (void)save:(id <GDCMessage>)message {
  [self cache:message.topic payload:message.payload];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      if (![NSKeyedArchiver archiveRootObject:message toFile:[self getPath:message.topic]]) {
        NSLog(@"%s failed, message: %@", __PRETTY_FUNCTION__, message);
      }
  });
}

- (id)getPayload:(NSString *)topic {
  id payload = [_cache objectForKey:topic];
  if (payload) {
    return payload;
  }
  id <GDCMessage> msg = [self getRetainedMessage:topic];
  if (msg.payload) {
    [self cache:topic payload:msg.payload];
  }
  return msg.payload;
}

- (id <GDCMessage>)getRetainedMessage:(NSString *)topic {
//  id <GDCMessage> msg = [_cache objectForKey:topic];
//  if (msg.options.retained) {
//    return msg;
//  }
  return [NSKeyedUnarchiver unarchiveObjectWithFile:[self getPath:topic]];
}

- (void)remove:(NSString *)topic {
  [_cache removeObjectForKey:topic];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      NSError *error = nil;
      if (![[NSFileManager defaultManager] removeItemAtPath:[self getPath:topic] error:&error]) {
        NSLog(@"%s failed, topic: %@", __PRETTY_FUNCTION__, topic);
      }
  });
}

- (NSString *)getPath:(NSString *)topic {
  topic = [topic stringByReplacingOccurrencesOfString:@"/" withString:@":"];
  return [[_baseDir stringByAppendingPathComponent:topic] stringByAppendingPathExtension:fileExtension];
}

+ (BOOL)patchRecursively:(id)original with:(id)patch {
  BOOL originalIsEntry = [original conformsToProtocol:@protocol(GDCEntry)];
  BOOL patchIsEntry = [patch conformsToProtocol:@protocol(GDCEntry)];
  if ((!originalIsEntry && ![original isKindOfClass:NSMutableDictionary.class]) || (!patchIsEntry && ![patch isKindOfClass:NSDictionary.class])) {
    return NO;
  }
  if (originalIsEntry) {
    [original setValue:@YES forKey:@"_inhibitNotify"];
    if (patchIsEntry) {
      [((MTLModel *) original) mergeValuesForKeysFromModel:patch];
    } else {
      NSMutableDictionary *expandedPatch = [NSMutableDictionary dictionary];
      [self expandDictionary:patch to:expandedPatch];
      [self patchEntry:original withDictionary:expandedPatch];
    }
    [original setValue:@NO forKey:@"_inhibitNotify"];
    return YES;
  }

  if (patchIsEntry) {
    patch = [(GDCEntry *) patch toDictionary];
  } else {
    NSMutableDictionary *expandedPatch = [NSMutableDictionary dictionary];
    [self expandDictionary:patch to:expandedPatch];
    patch = expandedPatch;
  }
  for (NSString *key in patch) {
    id value = patch[key];
    if (!original[key] || ![self patchRecursively:original[key] with:value]) {
      original[key] = value;
    }
  }
  return YES;
}

+ (void)expandDictionary:(NSDictionary *)dict to:(NSMutableDictionary *)toRtn {
  void (^block)() = ^(NSMutableDictionary *res, NSString *key, id value) {
      if (![value isKindOfClass:NSDictionary.class]) {
        res[key] = value;
        return;
      }
      if (![res[key] isKindOfClass:NSMutableDictionary.class]) {
        res[key] = [NSMutableDictionary dictionary];
      }
      [self expandDictionary:value to:res[key]];
  };
  for (NSString *keypath in dict) {
    if (![keypath containsString:@"."]) {
      block(toRtn, keypath, dict[keypath]);
      continue;
    }
    NSArray *components = [keypath componentsSeparatedByString:@"."];
    NSMutableDictionary *result = toRtn;
    for (int i = 0; i < components.count - 1; i++) {
      NSString *key = components[i];
      if (![result[key] isKindOfClass:NSMutableDictionary.class]) {
        result[key] = [NSMutableDictionary dictionary];
      }
      result = result[key];
    }
    block(result, components.lastObject, dict[keypath]);
  }
}

+ (NSDictionary *)flattedDictionary:(NSDictionary *)toFlat parentKey:(NSString *)parentKey {
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  for (NSString *key in toFlat) {
    id value = toFlat[key];
    if ([value isKindOfClass:NSDictionary.class]) {
      NSString *subKey = parentKey ? [parentKey stringByAppendingFormat:@"%@.", key] : [key stringByAppendingString:@"."];
      [dict addEntriesFromDictionary:[self flattedDictionary:value parentKey:subKey]];
    } else { // if ([value isKindOfClass:NSString.class] || [value isKindOfClass:NSNumber.class]) {
      NSString *subKey = parentKey ? [parentKey stringByAppendingString:key] : key;
      dict[subKey] = value;
    }
  }
  return dict;
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

+ (NSMutableDictionary *)mutableContainersAndLeaves:(NSDictionary *)dict {
  NSMutableDictionary *toRtn = [dict isKindOfClass:NSMutableDictionary.class] ? dict : [dict mutableCopy];
  [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
      if (![value isKindOfClass:NSDictionary.class]) {
        return;
      }
      toRtn[key] = [self mutableContainersAndLeaves:value];
  }];
  return toRtn;
}
@end