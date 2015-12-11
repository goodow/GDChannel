//
// Created by Larry Tin on 15/12/8.
//

#import "GDCStorage.h"
#import "GDCMessage.h"

static NSString *const fileExtension = @"archive";

@interface GDCStorage () <NSCacheDelegate>
@end

@implementation GDCStorage {
  NSString *_baseDir;
}

- (instancetype)initWithBaseDirectory:(NSString *)baseDir {
  self = [super init];
  if (self) {
    _cache = [[NSCache alloc] init];
    _cache.name = @"GDChannel";
    _cache.delegate = self;

    if (baseDir) {
      _baseDir = baseDir;
    } else {
      NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
      _baseDir = [[cachesDir stringByAppendingPathComponent:@"GDChannel"] stringByAppendingPathComponent:@"messages"];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:_baseDir]) {
      NSError *error = nil;
      if (![[NSFileManager defaultManager] createDirectoryAtPath:_baseDir
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&error]) {
        NSLog(@"[%@] Error creating directory: %@", __PRETTY_FUNCTION__, error);
      }
    }
  }

  return self;
}

- (id <GDCMessage>)cache:(id <GDCMessage>)message {
  [self.cache setObject:message forKey:message.topic];
  return message;
}

- (void)save:(id <GDCMessage>)message {
  [self cache:message];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      if (![NSKeyedArchiver archiveRootObject:message toFile:[self getPath:message.topic]]) {
        NSLog(@"%@ failed, message: %@", __PRETTY_FUNCTION__, message);
      }
  });
}

- (id <GDCMessage>)get:(NSString *)topic {
  id <GDCMessage> msg = [self.cache objectForKey:topic];
  if (msg) {
    return msg;
  }
  msg = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getPath:topic]];
  [self cache:msg];
  return msg;
}

- (void)remove:(NSString *)topic {
  [self.cache removeObjectForKey:topic];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      NSError *error = nil;
      if (![[NSFileManager defaultManager] removeItemAtPath:[self getPath:topic] error:&error]) {
        NSLog(@"%@ failed, topic: %@", __PRETTY_FUNCTION__, topic);
      }
  });
}

- (NSString *)getPath:(NSString *)topic {
  return [[_baseDir stringByAppendingPathComponent:topic] stringByAppendingPathExtension:fileExtension];
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj {

}

+ (NSDictionary *)mergeDictionaryRecursively:(NSDictionary *)original with:(NSDictionary *)change {
  if (![original isKindOfClass:NSDictionary.class]) {
    return change;
  }
  NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:original];
  for (NSString *key in change) {
    if (dict[key] && [change[key] isKindOfClass:NSDictionary.class]) {
      dict[key] = [self mergeDictionaryRecursively:dict[key] with:change[key]];
    } else {
      dict[key] = change[key];
    }
  }
  return dict;
}
@end