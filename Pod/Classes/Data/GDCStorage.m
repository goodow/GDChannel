//
// Created by Larry Tin on 15/12/8.
//

#import "GDCStorage.h"
#import "GDCMessage.h"

static NSString *const fileExtension = @"archive";

@interface GDCStorage ()
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

+ (id)patchRecursively:(id)original with:(id)patch {
  if ([original conformsToProtocol:@protocol(GDCEntry)]) {
    original = [(GDCEntry *) original toDictionary];
  }
  if ([patch conformsToProtocol:@protocol(GDCEntry)]) {
    patch = [(GDCEntry *) patch toDictionary];
  }
  if (![original isKindOfClass:NSDictionary.class] || ![patch isKindOfClass:NSDictionary.class]) {
    return patch;
  }
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:original];
  for (NSString *key in patch) {
    dict[key] = [self patchRecursively:dict[key] with:patch[key]];
  }
  return dict;
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
@end