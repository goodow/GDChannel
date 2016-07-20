//
// Created by Larry Tin on 7/20/16.
//

#import "NSMutableDictionary+GDCSerializable.h"


@implementation NSMutableDictionary (GDCSerializable)

+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr {
  return json.mutableCopy;
}

- (void)mergeFromJson:(nullable NSDictionary *)json {
  if (!json || json == NSNull.null) {
    [self removeAllObjects];
    return;
  }
  for (NSString *key in json) {
    id value = self[key];
    id newValue = json[key];
    if (!value || ![value isKindOfClass:NSMutableDictionary.class]
        || ![newValue isKindOfClass:NSDictionary.class]) {
      self[key] = newValue;
      continue;
    }
    [value mergeFromJson:newValue];
  }
}

- (NSDictionary *)toJson {
  return self;
}

- (void)mergeFrom:(id)other {
  if (other && ![other isKindOfClass:NSDictionary.class]) {
    return;
  }
  [self mergeFromJson:other];
}

@end