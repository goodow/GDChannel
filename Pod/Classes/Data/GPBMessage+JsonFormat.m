//
// Created by Larry Tin.
//

#import "GPBMessage+JsonFormat.h"
#import "GPBDescriptor.h"
#import "GPBUtilities.h"
#import "GPBDictionary.h"
#import "GPBDictionary_PackagePrivate.h"

@implementation GPBMessage (JsonFormat)

+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr {
  GPBMessage *msg = [[self alloc] init];
  return [msg mergeFromJson:json];
}

- (instancetype)mergeFromJson:(NSDictionary *)json {
  [self.class merge:json message:self];
  return self;
}

- (NSDictionary *)json {
  NSDictionary *json = [self.class printMessage:self];
  return json;
}

#pragma mark  Parses from JSON into a protobuf message.

+ (void)merge:(NSDictionary *)json message:(GPBMessage *)msg {
  [self assert:json isKindOfClass:NSDictionary.class];
  GPBDescriptor *descriptor = [msg.class descriptor];
  for (NSString *key in json) {
    GPBFieldDescriptor *field = [descriptor fieldWithName:key];
    if (!field) {
      field = [self fieldWithTextFormatName:key inDescriptor:descriptor];
      if (!field) {
        // message doesn't have the field set, on to the next.
        continue;
      }
    }
    [self mergeField:field json:json[key] message:msg];
  }
}

+ (void)mergeField:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
  if (json == NSNull.null) {
    return;
  }

  switch (field.fieldType) {
    case GPBFieldTypeSingle:
      [self parseFieldValue:field json:json message:msg];
      break;
    case GPBFieldTypeRepeated:
      [self mergeRepeatedField:field json:json message:msg];
      break;
    case GPBFieldTypeMap:
      [self mergeMapField:field json:json message:msg];
      break;
  }
}

+ (void)parseFieldValue:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
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
      if ([json isEqualToNumber:@(0)]) {
        return;
      }
      [msg setValue:[json copy] forKey:field.name];
      break;
    case GPBDataTypeEnum:
      [self assert:json isKindOfClass:NSString.class];
      int32_t outValue;
      [field.enumDescriptor getValue:&outValue forEnumName:json];
      [msg setValue:@(outValue) forKey:field.name];
      break;
    case GPBDataTypeBytes: // todo: convert NSString to NSData
    case GPBDataTypeString:
      [self assert:json isKindOfClass:NSString.class];
      if ([json length] == 0) {
        return;
      }
      [msg setValue:[json copy] forKey:field.name];
      break;
    case GPBDataTypeGroup:
    case GPBDataTypeMessage: {
      [self assert:json isKindOfClass:NSDictionary.class];
      if ([json count] == 0) {
        return;
      }
      GPBMessage *message = [[field.msgClass alloc] init];
      [self merge:json message:message];
      [msg setValue:message forKey:field.name];
      break;
    }
  }
}

+ (void)mergeRepeatedField:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
  [self assert:json isKindOfClass:NSArray.class];
  if ([json count] <= 0) {
    return;
  }
  id genericArray = [msg valueForKey:field.name];
  for (id ele in json) {
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
        [self assert:ele isKindOfClass:NSNumber.class];
        [(GPBInt32Array *) genericArray addValue:[ele doubleValue]];
        break;
      case GPBDataTypeEnum:
        [self assert:ele isKindOfClass:NSString.class];
        int32_t outValue;
        [field.enumDescriptor getValue:&outValue forEnumName:ele];
        [(GPBEnumArray *) genericArray addRawValue:outValue];
        break;
      case GPBDataTypeBytes: // todo: convert NSString to NSData
      case GPBDataTypeString: {
        [self assert:ele isKindOfClass:NSString.class];
        [(NSMutableArray *) genericArray addObject:[ele copy]];
        break;
      }
      case GPBDataTypeGroup:
      case GPBDataTypeMessage: {
        [self assert:ele isKindOfClass:NSDictionary.class];
        GPBMessage *message = [[field.msgClass alloc] init];
        [self merge:ele message:message];
        [(NSMutableArray *) genericArray addObject:message];
        break;
      }
    }
  }
}

+ (void)mergeMapField:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
  [self assert:json isKindOfClass:NSDictionary.class];
  id map = [msg valueForKey:field.name];
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = field.dataType;
  if (keyDataType == GPBDataTypeString && (valueDataType == GPBDataTypeString || valueDataType == GPBDataTypeBytes || valueDataType == GPBDataTypeMessage)) {
    // Cases where keys are strings and values are strings, bytes, or messages are handled by NSMutableDictionary.
    for (NSString *key in json) {
      id val = json[key];
      switch (valueDataType) {
        case GPBDataTypeBytes:
        case GPBDataTypeString:
          [self assert:val isKindOfClass:NSString.class];
          ((NSMutableDictionary *) map)[key] = [val copy];
          break;
//        case GPBDataTypeGroup:
        case GPBDataTypeMessage: {
          [self assert:val isKindOfClass:NSDictionary.class];
          GPBMessage *message = [[field.msgClass alloc] init];
          [self merge:val message:message];
          ((NSMutableDictionary *) map)[key] = message;
          break;
        }
      }
    }
    return;
  }
  // Other cases are: GBP<KEY><VALUE>Dictionary
  for (NSString *key in json) {
    id val = json[key];
    GPBGenericValue genericKey = [self readValue:key dataType:keyDataType field:field];
    GPBGenericValue genericValue = [self readValue:val dataType:valueDataType field:field];
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
      int32_t outValue;
      [field.enumDescriptor getValue:&outValue forEnumName:val];
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
      valueToFill.valueData = [val copy]; // todo: convert NSString to NSData
      break;
    case GPBDataTypeString:
      valueToFill.valueString = [val copy];
      break;
    case GPBDataTypeMessage: {
      GPBMessage *message = [[field.msgClass alloc] init];
      [self merge:val message:message];
      valueToFill.valueMessage = message;
      break;
    }
    case GPBDataTypeGroup:
      NSCAssert(NO, @"Can't happen");
      break;
  }
  return valueToFill;
}

#pragma mark  Converts protobuf message to JSON format.

+ (NSDictionary *)printMessage:(GPBMessage *)msg {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  GPBDescriptor *descriptor = [msg.class descriptor];
  for (GPBFieldDescriptor *field in descriptor.fields) {
    if (!GPBMessageHasFieldSet(msg, field)) {
      // Nothing to print, out of here.
      continue;
    }
    id jsonVal = [self printField:field value:[msg valueForKey:field.name]];
    json[field.name] = jsonVal;
  }
  return json;
}

+ (id)printField:(GPBFieldDescriptor *)field value:(id)val {
  switch (field.fieldType) {
    case GPBFieldTypeSingle:
      return [self printSingleFieldValue:field value:val];
    case GPBFieldTypeRepeated:
      return [self printRepeatedFieldValue:field value:val];
    case GPBFieldTypeMap:
      return [self printMapFieldValue:field value:val];
  }
  return nil;
}

+ (id)printSingleFieldValue:(GPBFieldDescriptor *)field value:(id)val {
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
    case GPBDataTypeBytes:
      return [val copy];
    case GPBDataTypeEnum: {
      NSString *valueStr = [field.enumDescriptor textFormatNameForValue:[val intValue]];
      return valueStr ?: [val copy];
    }
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      return [self printMessage:val];
  }
}

+ (id)printRepeatedFieldValue:(GPBFieldDescriptor *)field value:(id)arrayVal {
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
        [json addObject:[self printMessage:ele]];
      }
      break;
  }
  return json;
}

+ (id)printMapFieldValue:(GPBFieldDescriptor *)field value:(id)mapVal {
  NSMutableDictionary *json = [NSMutableDictionary dictionary];
  GPBDataType keyDataType = field.mapKeyDataType;
  GPBDataType valueDataType = field.dataType;
  if (keyDataType == GPBDataTypeString && (valueDataType == GPBDataTypeString || valueDataType == GPBDataTypeBytes || valueDataType == GPBDataTypeMessage)) {
    // Cases where keys are strings and values are strings, bytes, or messages are handled by NSMutableDictionary.
    [self assert:mapVal isKindOfClass:NSDictionary.class];
    for (NSString *key in mapVal) {
      id jsonVal;
      switch (valueDataType) {
        case GPBDataTypeBytes:
        case GPBDataTypeString:
          jsonVal = [mapVal[key] copy];
          break;
//        case GPBDataTypeGroup:
        case GPBDataTypeMessage:
          jsonVal = [self printMessage:mapVal[key]];
          break;
      }
      json[key] = jsonVal;
    };
    return json;
  }

  // Other cases are: GBP<KEY><VALUE>Dictionary
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
    case GPBDataTypeEnum:
    case GPBDataTypeBytes:
    case GPBDataTypeString:
    case GPBDataTypeGroup:
    case GPBDataTypeMessage: {
      // The exact type doesn't matter, they all implement -enumerateForTextFormat:.
      id <GPBDictionaryInternalsProtocol> dict = (GPBStringInt32Dictionary *) mapVal;
      [dict enumerateForTextFormat:^(id keyObj, id valueObj) {
          if (field.dataType == GPBDataTypeEnum) {
            NSString *valueStr = [field.enumDescriptor textFormatNameForValue:[valueObj intValue]];
            json[keyObj] = valueStr ?: valueObj;
          } else {
            json[keyObj] = valueObj;
          }
      }];
      break;
    }
  }
  return json;
}

#pragma mark  Exception assert

+ (void)assert:(id)value isKindOfClass:(Class)clz {
  if (![value isKindOfClass:clz]) {
    [NSException raise:NSInvalidArgumentException format:@"[%@]Invalid %@ value: %@", NSStringFromClass(self.class), NSStringFromClass(clz), value];
  }
}
@end