//
// Created by Larry Tin on 15/12/8.
//

#import "GDCStorage.h"
#import "GDCMessage.h"
#import "GDCMessageImpl.h"
#import "Channel.pbobjc.h"

static NSString *const fileExtension = @"archive";

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

- (GDCPBMessage *)convertMessageToProtobuf:(GDCMessageImpl *)msg {
  GDCPBMessage *message = [GDCPBMessage message];
  message.topic = msg.topic;
  message.replyTopic = msg.replyTopic;
  message.local = msg.local;
  message.send = msg.send;

  if (msg.payload) {
    GPBAny *payload = message.payload;
    payload.typeURL = [NSString stringWithFormat:@"gdc://any/%@", [msg.payload class]];
    if ([msg.payload isKindOfClass:GPBMessage.class]) {
      payload.value = ((GPBMessage *) msg.payload).data;
    } else {
      NSError *error;
      payload.value = [NSJSONSerialization dataWithJSONObject:msg.payload
                                                      options:0
                                                        error:&error];
    }
  }

  if (msg.options) {
    GDCPBMessage_Options *options = message.options;
    GDCOptions *opt = msg.options;
    options.retained = opt.retained;
    options.patch = opt.patch;
    options.timeout = opt.timeout;
    options.qos = opt.qos;
    if (opt.extras) {
      GPBAny *extras = options.extras;
      extras.typeURL = [NSString stringWithFormat:@"gdc://any/%@", [opt.extras class]];
      if ([opt.extras isKindOfClass:GPBMessage.class]) {
        extras.value = ((GPBMessage *) opt.extras).data;
      } else {
        NSError *error;
        extras.value = [NSJSONSerialization dataWithJSONObject:opt.extras
                                                        options:0
                                                          error:&error];
      }
    }
  }
}
@end