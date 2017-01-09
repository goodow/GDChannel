//
// Created by Larry Tin.
//

#import "GPBMessage+JsonFormat.h"
#import "GPBDescriptor.h"
#import "GPBArray.h"
#import "GPBUtilities.h"
#import "GPBDictionary_PackagePrivate.h"

static NSString *const arraySuffix = @"Array";

@implementation GPBMessage (JsonFormat)

+ (instancetype)parseFromJson:(nullable NSDictionary *)json error:(NSError **)errorPtr {
  @try {
    GPBMessage *msg = [[self alloc] init];
    [self merge:json message:msg ignoreDefaultValue:YES];
    if (errorPtr) {
      *errorPtr = nil;
    }
    return msg;
  } @catch (NSException *exception) {
    if (errorPtr) {
      NSDictionary *userInfo = exception.reason.length ? @{@"Reason": exception.reason} : nil;
      *errorPtr = [NSError errorWithDomain:GPBMessageErrorDomain code:-105 userInfo:userInfo];
    }
  }
  return nil;
}

- (void)mergeFromJson:(nullable NSDictionary *)json {
  [self.class merge:json message:self ignoreDefaultValue:NO];
}

- (NSDictionary *)toJson {
  @try {
    NSDictionary *json = [self.class printMessage:self useTextFormatKey:NO];
    return json;
  } @catch (NSException *exception) {
    // This really shouldn't happen. The only way printMessage:
    // could throw is if something in the library has a bug.
#ifdef DEBUG
    NSLog(@"%@: Internal exception while building message json: %@", self.class, exception);
#endif
  }
  return nil;
}

#pragma mark  Parses from JSON into a protobuf message.

+ (void)merge:(nullable NSDictionary *)json message:(GPBMessage *)msg ignoreDefaultValue:(BOOL)ignoreDefVal {
  if (!json || json == NSNull.null) {
    if (!ignoreDefVal) {
      [msg clear];
    }
    return;
  }
  [self assert:json isKindOfClass:NSDictionary.class];
  GPBDescriptor *descriptor = [msg.class descriptor];
  for (NSString *key in json) {
    id val = json[key];
    if (ignoreDefVal && val == NSNull.null) {
      continue;
    }
    GPBFieldDescriptor *field = [descriptor fieldWithName:key];
    field = field ?: [self fieldWithTextFormatName:key inDescriptor:descriptor];
    if (!field) {
      if (![key hasSuffix:arraySuffix]) {
        field = [descriptor fieldWithName:[key stringByAppendingString:arraySuffix]];
        if (field.fieldType != GPBFieldTypeRepeated) {
          field = nil;
        }
      }
      if (!field) {
        // message doesn't have the field set, on to the next.
        continue;
      }
    }
    if (val == NSNull.null) {
      id defVal = field.fieldType == GPBFieldTypeSingle ? [self defaultValueForFieldDataType:field.dataType] : nil;
      [msg setValue:defVal forKey:field.name];
    } else {
      [self mergeField:field json:val message:msg ignoreDefaultValue:ignoreDefVal];
    }
  }
}

+ (void)mergeField:(GPBFieldDescriptor *)field json:(nonnull id)json message:(GPBMessage *)msg ignoreDefaultValue:(BOOL)ignoreDefVal {
  switch (field.fieldType) {
    case GPBFieldTypeSingle:
      [self parseFieldValue:field json:json message:msg ignoreDefaultValue:ignoreDefVal];
      break;
    case GPBFieldTypeRepeated:
      [self mergeRepeatedField:field json:json message:msg ignoreDefaultValue:ignoreDefVal];
      break;
    case GPBFieldTypeMap:
      [self mergeMapField:field json:json message:msg ignoreDefaultValue:ignoreDefVal];
      break;
  }
}

+ (void)parseFieldValue:(GPBFieldDescriptor *)field json:(nonnull id)json message:(GPBMessage *)msg ignoreDefaultValue:(BOOL)ignoreDefVal {
  switch (field.dataType) {
    case GPBDataTypeBool:
    case GPBDataTypeSFixed32:
    case GPBDataTypeInt32:
    case GPBDataTypeSInt32:
    case GPBDataTypeFixed32:
    case GPBDataTypeUInt32:
    case GPBDataTypeSFixed64:
    case GPBDataTypeInt64:
    case GPBDataTypeSInt64:
    case GPBDataTypeFixed64:
    case GPBDataTypeUInt64:
    case GPBDataTypeFloat:
    case GPBDataTypeDouble:
      [self assert:json isKindOfClass:NSNumber.class];
      if (ignoreDefVal && [json isEqualToNumber:@(0)]) {
        return;
      }
      [msg setValue:[json copy] forKey:field.name];
      break;
    case GPBDataTypeEnum:
      if ([json isKindOfClass:NSNumber.class]) {
        [msg setValue:json forKey:field.name];
      } else {
        [self assert:json isKindOfClass:NSString.class];
        int32_t outValue;
        if ([field.enumDescriptor getValue:&outValue forEnumTextFormatName:json]) {
          [msg setValue:@(outValue) forKey:field.name];
        }
      }
      break;
    case GPBDataTypeBytes:
    case GPBDataTypeString: {
      [self assert:json isKindOfClass:NSString.class];
      if (ignoreDefVal && [json length] == 0) {
        return;
      }
      id value;
      if (field.dataType == GPBDataTypeBytes) {
        value = [[NSData alloc] initWithBase64EncodedString:json options:0];
      } else {
        value = [json copy];
      }
      [msg setValue:value forKey:field.name];
      break;
    }
    case GPBDataTypeGroup:
    case GPBDataTypeMessage: {
      [self assert:json isKindOfClass:NSDictionary.class];
      if (ignoreDefVal && [json count] == 0) {
        return;
      }
      GPBMessage *message = [msg valueForKey:field.name];
      [self merge:json message:message ignoreDefaultValue:ignoreDefVal];
      break;
    }
  }
}

+ (void)mergeRepeatedField:(GPBFieldDescriptor *)field json:(nonnull id)json message:(GPBMessage *)msg ignoreDefaultValue:(BOOL)ignoreDefVal {
  [self assert:json isKindOfClass:NSArray.class];
  if ([json count] <= 0) {
    return;
  }
  id genericArray = [msg valueForKey:field.name];
  for (id ele in json) {
    if (ignoreDefVal && ele == NSNull.null) {
      continue;
    }
    switch (field.dataType) {
      case GPBDataTypeBool:
      case GPBDataTypeSFixed32:
      case GPBDataTypeInt32:
      case GPBDataTypeSInt32:
      case GPBDataTypeFixed32:
      case GPBDataTypeUInt32:
      case GPBDataTypeSFixed64:
      case GPBDataTypeInt64:
      case GPBDataTypeSInt64:
      case GPBDataTypeFixed64:
      case GPBDataTypeUInt64:
      case GPBDataTypeFloat:
      case GPBDataTypeDouble: {
        double val = 0;
        if (ele != NSNull.null) {
          [self assert:ele isKindOfClass:NSNumber.class];
          val = [ele doubleValue];
        }
        [(GPBInt32Array *) genericArray addValue:val];
        break;
      }
      case GPBDataTypeEnum: {
        int32_t outValue = 0;
        if (ele != NSNull.null) {
          if ([json isKindOfClass:NSNumber.class]) {
            outValue = [json intValue];
          } else {
            [self assert:ele isKindOfClass:NSString.class];
            [field.enumDescriptor getValue:&outValue forEnumTextFormatName:ele];
          }
        }
        [(GPBEnumArray *) genericArray addRawValue:outValue];
        break;
      }
      case GPBDataTypeBytes:
      case GPBDataTypeString: {
        id val;
        if (ele != NSNull.null) {
          [self assert:ele isKindOfClass:NSString.class];
          if (field.dataType == GPBDataTypeBytes) {
            val = [[NSData alloc] initWithBase64EncodedString:ele options:0];
          } else {
            val = [ele copy];
          }
        } else {
          val = [self defaultValueForFieldDataType:field.dataType];
        }
        [(NSMutableArray *) genericArray addObject:val];
        break;
      }
      case GPBDataTypeGroup:
      case GPBDataTypeMessage: {
        GPBMessage *val = [[field.msgClass alloc] init];
        if (ele != NSNull.null) {
          [self assert:ele isKindOfClass:NSDictionary.class];
          [self merge:ele message:val ignoreDefaultValue:ignoreDefVal];
        }
        [(NSMutableArray *) genericArray addObject:val];
        break;
      }
    }
  }
}

+ (void)mergeMapField:(GPBFieldDescriptor *)field json:(nonnull id)json message:(GPBMessage *)msg ignoreDefaultValue:(BOOL)ignoreDefVal {
  [self assert:json isKindOfClass:NSDictionary.class];
  id map = [msg valueForKey:field.name];
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = field.dataType;
  if (keyDataType == GPBDataTypeString && GPBDataTypeIsObject(valueDataType)) {
    // Cases where keys are strings and values are strings, bytes, or messages are handled by NSMutableDictionary.
    for (NSString *key in json) {
      id value = json[key];
      if (ignoreDefVal && value == NSNull.null) {
        continue;
      }
      switch (valueDataType) {
        case GPBDataTypeBytes:
        case GPBDataTypeString: {
          NSString *val;
          if (value != NSNull.null) {
            [self assert:value isKindOfClass:NSString.class];
            if (field.dataType == GPBDataTypeBytes) {
              val = [[NSData alloc] initWithBase64EncodedString:value options:0];
            } else {
              val = [value copy];
            }
          } else {
            val = [self defaultValueForFieldDataType:valueDataType];
          }
          ((NSMutableDictionary *) map)[key] = val;
          break;
        }
        case GPBDataTypeGroup:
        case GPBDataTypeMessage: {
          GPBMessage *val = ((NSMutableDictionary *) map)[key] ?: [[field.msgClass alloc] init];
          if (value != NSNull.null) {
            [self assert:value isKindOfClass:NSDictionary.class];
            [self merge:value message:val ignoreDefaultValue:ignoreDefVal];
          } else {
            [val clear];
          }
          ((NSMutableDictionary *) map)[key] = val;
          break;
        }
      }
    }
    return;
  }
  // Other cases are: GPB<KEY><VALUE>Dictionary
  for (NSString *key in json) {
    id value = json[key];
    if (ignoreDefVal && value == NSNull.null) {
      continue;
    }
    GPBGenericValue genericKey = [self readValue:key dataType:keyDataType field:field];
    GPBGenericValue genericValue = field.defaultValue;
    if (value != NSNull.null) {
      if (valueDataType == GPBDataTypeMessage) {
        int numKey = key.intValue;
        GPBMessage *msgVal = [(GPBUInt32ObjectDictionary *) map objectForKey:numKey];
        msgVal = msgVal ?: [[field.msgClass alloc] init];
        [self merge:value message:msgVal ignoreDefaultValue:ignoreDefVal];
        genericValue.valueMessage = msgVal;
        // must hold msgVal which is declared in a if block until the use of outside scope(setGPBGenericValue:forGPBGenericValueKey)
        value = msgVal;
      } else {
        genericValue = [self readValue:value dataType:valueDataType field:field];
      }
    }
    [map setGPBGenericValue:&genericValue forGPBGenericValueKey:&genericKey];
  }
}

+ (GPBFieldDescriptor *)fieldWithTextFormatName:(NSString *)name inDescriptor:(GPBDescriptor *)descriptor {
  for (GPBFieldDescriptor *field in descriptor.fields) {
    if ([field.textFormatName isEqual:name]) {
      return field;
    }
  }
  return nil;
}

+ (nullable id)defaultValueForFieldDataType:(GPBDataType)dataType {
  switch (dataType) {
    case GPBDataTypeBool:
    case GPBDataTypeSFixed32:
    case GPBDataTypeInt32:
    case GPBDataTypeSInt32:
    case GPBDataTypeFixed32:
    case GPBDataTypeUInt32:
    case GPBDataTypeSFixed64:
    case GPBDataTypeInt64:
    case GPBDataTypeSInt64:
    case GPBDataTypeFixed64:
    case GPBDataTypeUInt64:
    case GPBDataTypeFloat:
    case GPBDataTypeDouble:
    case GPBDataTypeEnum:
      return @0;
    case GPBDataTypeBytes:
      return [NSData data];
    case GPBDataTypeString:
      return @"";
    case GPBDataTypeGroup:
    case GPBDataTypeMessage:
      break;
  }
  return nil;
}

+ (GPBGenericValue)readValue:(id)val dataType:(GPBDataType)type field:(GPBFieldDescriptor *)field {
  GPBGenericValue valueToFill;
  switch (type) {
    case GPBDataTypeBool:
      valueToFill.valueBool = [val boolValue];
      break;
    case GPBDataTypeSFixed32:
      valueToFill.valueInt32 = [val intValue];
      break;
    case GPBDataTypeEnum: {
      int32_t outValue = 0;
      if ([val isKindOfClass:NSNumber.class]) {
        outValue = [val intValue];
      } else {
        [field.enumDescriptor getValue:&outValue forEnumTextFormatName:val];
      }
      valueToFill.valueEnum = outValue;
      break;
    }
    case GPBDataTypeInt32:
      valueToFill.valueInt32 = [val intValue];
      break;
    case GPBDataTypeSInt32:
      valueToFill.valueInt32 = [val intValue];
      break;
    case GPBDataTypeFixed32:
      valueToFill.valueUInt32 = [val unsignedIntValue];
      break;
    case GPBDataTypeUInt32:
      valueToFill.valueUInt32 = [val unsignedIntValue];
      break;
    case GPBDataTypeSFixed64:
      valueToFill.valueInt64 = [val longLongValue];
      break;
    case GPBDataTypeInt64:
      valueToFill.valueInt64 = [val longLongValue];
      break;
    case GPBDataTypeSInt64:
      valueToFill.valueInt64 = [val longLongValue];
      break;
    case GPBDataTypeFixed64:
      valueToFill.valueUInt64 = [val unsignedLongLongValue];
      break;
    case GPBDataTypeUInt64:
      valueToFill.valueUInt64 = [val unsignedLongLongValue];
      break;
    case GPBDataTypeFloat:
      valueToFill.valueFloat = [val floatValue];
      break;
    case GPBDataTypeDouble:
      valueToFill.valueDouble = [val doubleValue];
      break;
    case GPBDataTypeBytes:
      valueToFill.valueData = [[NSData alloc] initWithBase64EncodedString:val options:0];
      break;
    case GPBDataTypeString:
      valueToFill.valueString = [val copy];
      break;
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      NSCAssert(NO, @"Can't happen");
      break;
  }
  return valueToFill;
}

#pragma mark  Converts protobuf message to JSON format.

+ (NSDictionary *)printMessage:(GPBMessage *)msg useTextFormatKey:(BOOL)useTextFormatKey {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  GPBDescriptor *descriptor = [msg.class descriptor];
  for (GPBFieldDescriptor *field in descriptor.fields) {
    if (!GPBMessageHasFieldSet(msg, field)) {
      // Nothing to print, out of here.
      continue;
    }
    id jsonVal = [self printField:field value:[msg valueForKey:field.name] useTextFormatKey:useTextFormatKey];
    NSString *name = useTextFormatKey ? field.textFormatName : field.name;
    if (!useTextFormatKey && field.fieldType == GPBFieldTypeRepeated) {
      name = [name substringToIndex:name.length - arraySuffix.length];
    }
    json[name] = jsonVal;
  }
  return json;
}

+ (id)printField:(GPBFieldDescriptor *)field value:(id)val useTextFormatKey:(BOOL)useTextFormatKey {
  switch (field.fieldType) {
    case GPBFieldTypeSingle:
      return [self printSingleFieldValue:field value:val useTextFormatKey:useTextFormatKey];
    case GPBFieldTypeRepeated:
      return [self printRepeatedFieldValue:field value:val useTextFormatKey:useTextFormatKey];
    case GPBFieldTypeMap:
      return [self printMapFieldValue:field value:val useTextFormatKey:useTextFormatKey];
  }
  return nil;
}

+ (id)printSingleFieldValue:(GPBFieldDescriptor *)field value:(id)val useTextFormatKey:(BOOL)useTextFormatKey {
  switch (field.dataType) {
    case GPBDataTypeBool:
    case GPBDataTypeDouble:
    case GPBDataTypeFixed32:
    case GPBDataTypeFixed64:
    case GPBDataTypeFloat:
    case GPBDataTypeInt32:
    case GPBDataTypeInt64:
    case GPBDataTypeSFixed32:
    case GPBDataTypeSFixed64:
    case GPBDataTypeSInt32:
    case GPBDataTypeSInt64:
    case GPBDataTypeUInt32:
    case GPBDataTypeUInt64:
    case GPBDataTypeString:
      return [val copy];
    case GPBDataTypeBytes:
      return [(NSData *) val base64EncodedStringWithOptions:0];
    case GPBDataTypeEnum: {
      NSString *valueStr = [field.enumDescriptor textFormatNameForValue:[val intValue]];
      return valueStr ?: [val copy];
    }
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      return [self printMessage:val useTextFormatKey:useTextFormatKey];
  }
}

+ (id)printRepeatedFieldValue:(GPBFieldDescriptor *)field value:(id)arrayVal useTextFormatKey:(BOOL)useTextFormatKey {
  NSMutableArray *json = [NSMutableArray array];
  switch (field.dataType) {
    case GPBDataTypeBool:
    case GPBDataTypeDouble:
    case GPBDataTypeFixed32:
    case GPBDataTypeFixed64:
    case GPBDataTypeFloat:
    case GPBDataTypeInt32:
    case GPBDataTypeInt64:
    case GPBDataTypeSFixed32:
    case GPBDataTypeSFixed64:
    case GPBDataTypeSInt32:
    case GPBDataTypeSInt64:
    case GPBDataTypeUInt32:
    case GPBDataTypeUInt64: {
      // The exact type doesn't matter, they all implement -valueAtIndex:.
      GPBInt32Array *array = (GPBInt32Array *) arrayVal;
      for (NSUInteger i = 0; i < array.count; i++) {
        [json addObject:@([array valueAtIndex:i])];
      }
      break;
    }
    case GPBDataTypeEnum: {
      [(GPBEnumArray *) arrayVal enumerateRawValuesWithBlock:^(int32_t value, NSUInteger idx, BOOL *stop) {
          NSString *valueStr = [field.enumDescriptor textFormatNameForValue:value];
          [json addObject:valueStr ?: @(value)];
      }];
      break;
    }
    case GPBDataTypeBytes:
      [self assert:arrayVal isKindOfClass:NSArray.class];
      for (id ele in arrayVal) {
        [json addObject:[(NSData *) ele base64EncodedStringWithOptions:0]];
      }
      break;
    case GPBDataTypeString:
      [self assert:arrayVal isKindOfClass:NSArray.class];
      for (id ele in arrayVal) {
        [json addObject:[ele copy]];
      }
      break;
    case GPBDataTypeGroup:
    case GPBDataTypeMessage:
      [self assert:arrayVal isKindOfClass:NSArray.class];
      for (id ele in arrayVal) {
        [json addObject:[self printMessage:ele useTextFormatKey:useTextFormatKey]];
      }
      break;
  }
  return json;
}

+ (id)printMapFieldValue:(GPBFieldDescriptor *)field value:(id)mapVal useTextFormatKey:(BOOL)useTextFormatKey {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = field.dataType;
  if (keyDataType == GPBDataTypeString && GPBDataTypeIsObject(valueDataType)) {
    // Cases where keys are strings and values are strings, bytes, or messages are handled by NSMutableDictionary.
    [self assert:mapVal isKindOfClass:NSDictionary.class];
    for (NSString *key in mapVal) {
      id jsonVal;
      switch (valueDataType) {
        case GPBDataTypeBytes:
          jsonVal = [(NSData *) mapVal[key] base64EncodedStringWithOptions:0];
          break;
        case GPBDataTypeString:
          jsonVal = [mapVal[key] copy];
          break;
        case GPBDataTypeGroup:
        case GPBDataTypeMessage:
          jsonVal = [self printMessage:mapVal[key] useTextFormatKey:useTextFormatKey];
          break;
      }
      json[key] = jsonVal;
    };
    return json;
  }

  // Other cases are: GPB<KEY><VALUE>Dictionary
  // The exact type doesn't matter, they all implement -enumerateForTextFormat:.
  [(GPBStringInt32Dictionary *) mapVal enumerateForTextFormat:^(id keyObj, id valueObj) {
      switch (field.dataType) {
        case GPBDataTypeEnum: {
          NSString *valueStr = [field.enumDescriptor textFormatNameForValue:[valueObj intValue]];
          valueObj = valueStr ?: valueObj;
        }
        case GPBDataTypeGroup:
        case GPBDataTypeMessage: {
          valueObj = [valueObj toJson];
        }
        default:
          json[keyObj] = valueObj;
          break;
      }
  }];
  return json;
}

// copied from GPBUtilities_PackagePrivate.h
BOOL GPBDataTypeIsObject(GPBDataType type) {
  switch (type) {
    case GPBDataTypeBytes:
    case GPBDataTypeString:
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      return YES;
    default:
      return NO;
  }
}

#pragma mark  Exception assert

+ (void)assert:(id)value isKindOfClass:(Class)clz {
  if (![value isKindOfClass:clz]) {
    [NSException raise:NSInvalidArgumentException format:@"[%@]Invalid %@ value: %@", NSStringFromClass(self.class), NSStringFromClass(clz), value];
  }
}
@end