//
// Created by Larry Tin on 15/12/9.
//

#import "GDCOptions.h"
#import "GPBAny+GDChannel.h"

static long const kDefaultTimeout = 30 * 1000;

@implementation GDCOptions {
  BOOL _retained;
  BOOL _patch;
  long _timeout;
  enum GDCQualityOfService _qos;
  NSObject <GDCSerializable> *_extras;
}
- (instancetype)init {
  self = [super init];
  if (self) {
    _timeout = kDefaultTimeout;
  }
  return self;
}

- (GDCOptions *(^)(BOOL))retained {
  return ^id(BOOL retained) {
      _retained = retained;
      return self;
  };
}

- (GDCOptions *(^)(BOOL))patch {
  return ^GDCOptions *(BOOL patch) {
      _patch = patch;
      return self;
  };
}

- (GDCOptions *(^)(long))timeout {
  return ^GDCOptions *(long timeout) {
      _timeout = timeout;
      return self;
  };
}

- (GDCOptions *(^)(enum GDCQualityOfService))qos {
  return ^GDCOptions *(enum GDCQualityOfService qos) {
      _qos = qos;
      return self;
  };
}

- (GDCOptions *(^)(NSObject <GDCSerializable> *))extras {
  return ^GDCOptions *(NSObject <GDCSerializable> *extras) {
      if ([extras isKindOfClass:NSDictionary.class] && ![extras isKindOfClass:NSMutableDictionary.class]) {
        extras = [extras mutableCopy];
      }
      _extras = extras;
      return self;
  };
}

- (BOOL)isRetained {
  return _retained;
}

- (BOOL)isPatch {
  return _patch;
}

- (long)getTimeout {
  return _timeout;
}

- (enum GDCQualityOfService)getQos {
  return _qos;
}

- (__kindof NSObject <GDCSerializable> *)getExtras {
  return _extras;
}

#pragma mark GDCSerializable
static NSString *const kRetainedKey = @"retained";
static NSString *const kPatchKey = @"patch";
static NSString *const kTimeoutKey = @"timeout";
static NSString *const kQosKey = @"qos";
static NSString *const kExtrasKey = @"extras";

+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr {
  return GDCOptions.new
      .retained([json[kRetainedKey] boolValue])
      .patch([json[kPatchKey] boolValue])
      .timeout([json[kTimeoutKey] longValue])
      .qos([json[kQosKey] intValue])
      .extras([GPBAny unpackFromJson:json[kExtrasKey] error:nil]);
}

- (NSDictionary *)toJson {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  if (_retained) {
    json[kRetainedKey] = @(_retained);
  }
  if (_patch) {
    json[kPatchKey] = @(_patch);
  }
  if (_timeout != kDefaultTimeout) {
    json[kTimeoutKey] = @(_timeout);
  }
  if (_qos) {
    json[kQosKey] = @(_qos);
  }
  if (_extras) {
    json[kExtrasKey] = [GPBAny packToJson:_extras];
  }
  return json;
}

- (void)mergeFromJson:(NSDictionary *)json {
  id extras = json[kExtrasKey];
  [_extras mergeFromJson:extras];
}

- (void)mergeFrom:(GDCOptions *)other {
  [_extras mergeFrom:other.getExtras];
}

#pragma mark NSObject

- (NSString *)description {
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.toJson
                                                     options:NSJSONWritingPrettyPrinted
                                                       error:&error];
  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end