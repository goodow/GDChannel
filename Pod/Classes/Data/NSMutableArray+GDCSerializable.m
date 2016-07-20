//
// Created by Larry Tin on 16/7/21.
//

#import "NSMutableArray+GDCSerializable.h"


@implementation NSMutableArray (GDCSerializable)
+ (instancetype)parseFromJson:(nullable NSArray *)json error:(NSError **)errorPtr {
  return json.mutableCopy;
}

- (void)mergeFromJson:(nullable NSArray *)json {
  if (!json || json == NSNull.null) {
    [self removeAllObjects];
    return;
  }
  [self addObjectsFromArray:json];
}

- (NSDictionary *)toJson {
  return self;
}

- (void)mergeFrom:(id)other {
  if (other && ![other isKindOfClass:NSArray.class]) {
    return;
  }
  [self mergeFromJson:other];
}

@end