//
// Created by Larry Tin on 15/12/9.
//

#import "GDCOptions.h"

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
static NSString *const kTypeKey = @"type";
static NSString *const kTimeoutKey = @"timeout";
static NSString *const kExtrasKey = @"extras";
static NSString *const kExtrasTypeKey = @"@type";

+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr {
  GDCOptions *options = [[self alloc] init];
  options.retained = [json[kRetainedKey] boolValue];
  options.patch = [json[kPatchKey] boolValue];
  options.type = NSClassFromString(json[kTypeKey]);
  options.timeout = [json[kTimeoutKey] longValue];

  id extras = json[kExtrasKey];
  if ([extras isKindOfClass:NSDictionary.class]) {
    NSString *typeUrl = extras[kExtrasTypeKey];
    Class dataClass = NSClassFromString(typeUrl.lastPathComponent);
    if ([dataClass conformsToProtocol:@protocol(GDCSerializable)]) {
      NSError *error = nil;
      extras = [dataClass parseFromJson:extras error:&error];
    }
  }
  options.extras = extras;
  return options;
}

- (NSDictionary *)toJson {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  json[kRetainedKey] = @(self.retained);
  json[kPatchKey] = @(self.patch);
  json[kTypeKey] = NSStringFromClass(self.type);
  if (self.timeout != kDefaultTimeout) {
    json[kTimeoutKey] = @(self.timeout);
  }

  json[kExtrasKey] = self.extras.toJson.mutableCopy;
  if (![self.extras isKindOfClass:NSMutableDictionary.class] && ![self.extras isKindOfClass:NSMutableArray.class]) {
    json[kExtrasKey][kExtrasTypeKey] = [NSString stringWithFormat:@"gdc://any/%@", NSStringFromClass([self.extras class])];
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