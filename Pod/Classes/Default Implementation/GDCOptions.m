//
// Created by Larry Tin on 15/12/9.
//

#import "GDCOptions.h"
#import "GDCNotificationBus.h"

static long const kDefaultTimeout = 30 * 1000;

@implementation GDCOptions {

}
- (instancetype)init {
  self = [super init];
  if (self) {
    _timeout = kDefaultTimeout;
  }
  return self;
}

+ (GDCOptions *)optionWithExtras:(NSObject <GDCSerializable> *)extras {
  GDCOptions *options = [[self alloc] init];
  options.extras = extras;
  return options;
}

- (void)setExtras:(NSObject <GDCSerializable> *)extras {
  if ([extras isKindOfClass:NSDictionary.class] && ![extras isKindOfClass:NSMutableDictionary.class]) {
    extras = [extras mutableCopy];
  }
  _extras = extras;
}

#pragma mark GDCSerializable
static NSString *const kRetainedKey = @"retained";
static NSString *const kPatchKey = @"patch";
static NSString *const kTimeoutKey = @"timeout";
static NSString *const kQosKey = @"qos";
static NSString *const kExtrasKey = @"extras";

+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr {
  GDCOptions *options = [[self alloc] init];
  options.retained = [json[kRetainedKey] boolValue];
  options.patch = [json[kPatchKey] boolValue];
  options.timeout = [json[kTimeoutKey] longValue];
  options.qos = [json[kQosKey] intValue];

  options.extras = [GDCNotificationBus parseAnyType:json[kExtrasKey]];
  return options;
}

- (NSDictionary *)toJson {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  if (self.retained) {
    json[kRetainedKey] = @(self.retained);
  }
  if (self.patch) {
    json[kPatchKey] = @(self.patch);
  }
  if (self.timeout != kDefaultTimeout) {
    json[kTimeoutKey] = @(self.timeout);
  }
  if (self.qos) {
    json[kQosKey] = @(self.qos);
  }
  if (self.extras) {
    json[kExtrasKey] = self.extras.toJson.mutableCopy;
    if (![self.extras isKindOfClass:NSMutableDictionary.class] && ![self.extras isKindOfClass:NSMutableArray.class]) {
      json[kExtrasKey][kJsonTypeKey] = [NSString stringWithFormat:@"gdc://any/%@", NSStringFromClass([self.extras class])];
    }
  }
  return json;
}

- (void)mergeFromJson:(NSDictionary *)json {
  id extras = json[kExtrasKey];
  [self.extras mergeFromJson:extras];
}

- (void)mergeFrom:(GDCOptions *)other {
  [self.extras mergeFrom:other.extras];
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