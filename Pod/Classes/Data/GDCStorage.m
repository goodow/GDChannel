//
// Created by Larry Tin on 15/12/8.
//

#import "GDCStorage.h"
#import "GDCMessage.h"
#import "GDCMessageImpl.h"
#import "Channel.pbobjc.h"
#import "GPBAny+GDChannel.h"
#import "GDCOptions+ReadAccess.h"
#import "GDCBusProvider.h"

static NSString *const archiveFileExtension = @"archive";
static NSString *const protobufFileExtension = @"protobuf";

@implementation GDCStorage {
  NSString *_baseDir;
  NSMapTable *_cache;
}

+ (GDCStorage *)instance {
  static GDCStorage *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      instance = [[GDCStorage alloc] initWithBaseDirectory:nil];
  });
  return instance;
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
      if ([message.payload isKindOfClass:GPBMessage.class]) {
        GDCPBMessage *pbMessage = [GDCStorage convertMessageToProtobuf:message];
        NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:[self getPath:message.topic withExtension:protobufFileExtension] append:NO];
        @try {
          [outputStream open];
          [pbMessage writeToOutputStream:outputStream];
          [outputStream close];
        } @catch (NSException *exception) {
          NSLog(@"%s failed, message: %@", __PRETTY_FUNCTION__, message);
          [GDCBusProvider.instance publishLocal:[@"logReport/" stringByAppendingString:@"catch_exception"] payload:[(GDCMessageImpl *) message toJsonWithTopic:YES]];
        }
        return;
      }
      if (![NSKeyedArchiver archiveRootObject:message toFile:[self getPath:message.topic withExtension:archiveFileExtension]]) {
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
  NSData *data = [NSData dataWithContentsOfFile:[self getPath:topic withExtension:protobufFileExtension]];
  if (data) {
    NSError *error;
    GDCPBMessage *pbMessage = [GDCPBMessage parseFromData:data error:&error];
    return pbMessage ? [GDCStorage convertProtobufToMessage:pbMessage] : nil;
  }
  return [NSKeyedUnarchiver unarchiveObjectWithFile:[self getPath:topic withExtension:archiveFileExtension]];
}

- (void)remove:(NSString *)topic {
  [_cache removeObjectForKey:topic];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      NSError *error = nil;
      if (![[NSFileManager defaultManager] removeItemAtPath:[self getPath:topic withExtension:protobufFileExtension] error:&error]) {
        NSLog(@"%s failed, topic: %@", __PRETTY_FUNCTION__, topic);
      }
      [[NSFileManager defaultManager] removeItemAtPath:[self getPath:topic withExtension:archiveFileExtension] error:&error];
  });
}

- (NSString *)getPath:(NSString *)topic withExtension:(NSString *)fileExtension {
  topic = [topic stringByReplacingOccurrencesOfString:@"/" withString:@":"];
  return [[_baseDir stringByAppendingPathComponent:topic] stringByAppendingPathExtension:fileExtension];
}

+ (GDCPBMessage *)convertMessageToProtobuf:(GDCMessageImpl *)msg {
  GDCPBMessage *message = [GDCPBMessage message];
  message.topic = msg.topic;
  message.replyTopic = msg.replyTopic;
  message.local = msg.local;
  message.send = msg.send;

  if (msg.payload) {
    message.payload = [GPBAny pack:msg.payload withTypeUrlPrefix:nil];
  }

  if (msg.options) {
    GDCPBMessage_Options *options = message.options;
    GDCOptions *opt = msg.options;
    options.retained = opt.isRetained;
    options.patch = opt.isPatch;
    options.timeout = opt.getTimeout;
    options.qos = opt.getQos;
    if (opt.getExtras) {
      options.extras = [GPBAny pack:opt.getExtras withTypeUrlPrefix:nil];
    }
  }
  return message;
}

+ (id <GDCMessage>)convertProtobufToMessage:(GDCPBMessage *)message {
  GDCMessageImpl *msg = [[GDCMessageImpl alloc] init];
  msg.topic = message.topic;
  msg.replyTopic = message.replyTopic.length ? message.replyTopic : nil;
  msg.local = message.local;
  msg.send = message.send;

  if (message.hasPayload) {
    msg.payload = [message.payload unpack];
  }

  if (message.hasOptions) {
    GDCOptions *opt = GDCOptions.new;
    msg.options = opt;
    GDCPBMessage_Options *options = message.options;
    opt.retained(options.retained).patch(options.patch).timeout(options.timeout).qos(options.qos);
    if (options.hasExtras) {
      opt.extras([options.extras unpack]);
    }
  }
  return msg;
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
@end