//
// Created by Larry Tin on 16/8/8.
//

#import "GPBAny+GDChannel.h"
#import "GDCSerializable.h"
#import "GPBMessage+JsonFormat.h"

@implementation GPBAny (GDChannel)

+ (instancetype)pack:(id)value withTypeUrlPrefix:(NSString *)typeUrlPrefix {
  GPBAny *any = [GPBAny message];
  if ([value isKindOfClass:GPBMessage.class]) {
    any.typeURL = [self getTypeUrl:value withPrefix:typeUrlPrefix];
    any.value = ((GPBMessage *) value).data;
  } else {
    NSError *error;
    any.value = [NSJSONSerialization dataWithJSONObject:value
                                                options:0
                                                  error:&error];
  }
  return any;
}

- (__kindof id)unpack {
  if (self.typeURL.length) {
    return [[self.class getClassFromTypeUrl:self.typeURL] parseFromData:self.value error:nil];
  }
  NSError *error;
  return [NSJSONSerialization JSONObjectWithData:self.value
                                         options:NSJSONReadingAllowFragments | NSJSONReadingMutableContainers
                                           error:&error];
}

+ (id)packToJson:(id <GDCSerializable>)value {
  if ([value isKindOfClass:GPBMessage.class]) {
    NSMutableDictionary *json = [value toJson];
    json[kJsonTypeKey] = [self getTypeUrl:value withPrefix:nil];
    return json;
  } else if ([value isKindOfClass:NSArray.class]) {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:((NSArray *) value).count];
    for (id ele in value) {
      if ([ele isKindOfClass:GPBMessage.class]) {
        NSMutableDictionary *json = [ele toJson];
        json[kJsonTypeKey] = [self getTypeUrl:ele withPrefix:nil];
        [array addObject:json];
        continue;
      }
      [array addObject:ele];
    }
    return array;
  }
  return value;
}

+ (__kindof id)unpackFromJson:(id)json error:(NSError **)errorPtr {
  if ([json isKindOfClass:NSDictionary.class] && json[kJsonTypeKey]) {
    Class clz = [self getClassFromTypeUrl:json[kJsonTypeKey]];
    if ([clz conformsToProtocol:@protocol(GDCSerializable)]) {
      return [(id <GDCSerializable>) clz parseFromJson:json error:errorPtr];
    }
  }
  return json;
}

+ (NSString *)getTypeUrl:(id)value withPrefix:(NSString *)typeUrlPrefix {
  if (!typeUrlPrefix) {
    typeUrlPrefix = @"gdc://any";
  }
  return [typeUrlPrefix stringByAppendingPathComponent:NSStringFromClass([value class])];
}

+ (Class)getClassFromTypeUrl:(NSString *)typeUrl {
  NSArray<NSString *> *parts = [typeUrl componentsSeparatedByString:@"/"];
  if (parts.count == 1) {
    NSLog(@"Invalid type url found: %@", typeUrl);
  }
  parts = [parts.lastObject componentsSeparatedByString:@"."];
  return NSClassFromString(parts.lastObject);
}

@end