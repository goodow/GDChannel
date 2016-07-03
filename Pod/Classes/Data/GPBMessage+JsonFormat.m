//
// Created by Larry Tin.
//

#import "GPBMessage+JsonFormat.h"
#import "GPBDescriptor.h"
#import "GPBUtilities.h"
#import "GPBDictionary.h"

@implementation GPBMessage (JsonFormat)

+ (instancetype)parseFromJson:(NSData *)json error:(NSError **)errorPtr {
  NSError *error = nil;
  NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:json
                                                       options:0
                                                         error:&error];
  if (!dict) {
    [NSException raise:NSParseErrorException format:@"Can't parse JSON: %@", error];
  }

  GPBMessage *msg = [self message];
  [self assert:dict isKindOfClass:NSDictionary.class];
  [self merge:dict message:msg];
  return msg;
}

- (NSData *)json {
  NSDictionary *json = [self.class printMessage:self];
  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                     options:0
                                                       error:&error];
  if (!jsonData) {
    [NSException raise:NSInvalidArgumentException format:@"Failed to encode as JSON: %@", error];
  }
  return jsonData;
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
    case GPBDataTypeEnum:
    case GPBDataTypeString:
    case GPBDataTypeBytes:
      return val;
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
    case GPBDataTypeUInt64:
    case GPBDataTypeEnum: {
      // The exact type doesn't matter, they all implement -valueAtIndex:.
      GPBInt32Array *array = (GPBInt32Array *) arrayVal;
      for (NSUInteger i = 0; i < array.count; i++) {
        [json addObject:@([array valueAtIndex:i])];
      }
      break;
    }
    case GPBDataTypeString:
    case GPBDataTypeBytes:
      [self assert:arrayVal isKindOfClass:NSArray.class];
      for (id ele in arrayVal) {
        [json addObject:[ele copy]];
      }
      break;
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
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
    case GPBDataTypeEnum: {
      // The exact type doesn't matter, they all implement -valueAtIndex:.
      GPBStringInt32Dictionary *dict = (GPBStringInt32Dictionary *) mapVal;
      break;
    }
    case GPBDataTypeString:
    case GPBDataTypeBytes:
      [self assert:mapVal isKindOfClass:NSDictionary.class];
      for (NSString *key in mapVal) {
        json[key] = [mapVal[key] copy];
      }
      break;
    case GPBDataTypeMessage:
    case GPBDataTypeGroup:
      [self assert:mapVal isKindOfClass:NSDictionary.class];
      for (NSString *key in mapVal) {
        json[key] = [self printMessage:mapVal[key]];
      }
      break;
  }
  return json;
}


#pragma mark  Parses from JSON into a protobuf message.

+ (void)merge:(NSDictionary *)json message:(GPBMessage *)msg {
  GPBDescriptor *descriptor = [msg.class descriptor];
  for (NSString *key in json) {
    GPBFieldDescriptor *fieldDescriptor = [descriptor fieldWithName:key];
    if (!fieldDescriptor) {
      // message doesn't have the field set, on to the next.
      continue;
    }
    [self mergeField:fieldDescriptor json:json[key] message:msg];
  }
}

+ (void)mergeField:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
  if (GPBMessageHasFieldSet(msg, field)) {
    // todo: whether fields belonging to the same oneof has already been set
    [NSException raise:NSParseErrorException format:@"Field %@ has already been set.", field.name];
  }
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
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageBoolField(msg, field, [json boolValue]);
      break;
    case GPBDataTypeSFixed32:
    case GPBDataTypeEnum:
    case GPBDataTypeInt32:
    case GPBDataTypeSInt32:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageInt32Field(msg, field, [json intValue]);
      break;
    case GPBDataTypeFixed32:
    case GPBDataTypeUInt32:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageUInt32Field(msg, field, [json unsignedIntValue]);
      break;
    case GPBDataTypeSFixed64:
    case GPBDataTypeInt64:
    case GPBDataTypeSInt64:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageInt64Field(msg, field, [json longLongValue]);
      break;
    case GPBDataTypeFixed64:
    case GPBDataTypeUInt64:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageUInt64Field(msg, field, [json unsignedLongLongValue]);
      break;
    case GPBDataTypeFloat:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageFloatField(msg, field, [json floatValue]);
      break;
    case GPBDataTypeDouble:
      [self assert:json isKindOfClass:NSNumber.class];
      GPBSetMessageDoubleField(msg, field, [json doubleValue]);
      break;
    case GPBDataTypeString:
      [self assert:json isKindOfClass:NSString.class];
      if ([json length] > 0) {
        GPBSetMessageStringField(msg, field, json);
      }
      break;
    case GPBDataTypeMessage: {
      [self assert:json isKindOfClass:NSDictionary.class];
      if ([json count] > 0) {
        GPBMessage *message = [[field.msgClass alloc] init];
        [self merge:json message:message];
        GPBSetMessageMessageField(msg, field, message);
      }
      break;
    }
    case GPBDataTypeBytes:
      // todo: convert NSString to NSData
    case GPBDataTypeGroup:
      // todo: support group type
      break;
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
      case GPBDataTypeString: {
        [self assert:ele isKindOfClass:NSString.class];
        [(NSMutableArray *) genericArray addObject:[ele copy]];
        break;
      }
      case GPBDataTypeMessage: {
        [self assert:ele isKindOfClass:NSDictionary.class];
        GPBMessage *message = [[field.msgClass alloc] init];
        [self merge:ele message:message];
        [(NSMutableArray *) genericArray addObject:message];
        break;
      }
      case GPBDataTypeBytes:
        // todo: convert NSString to NSData
      case GPBDataTypeGroup:
        // todo: support group type
        break;
      case GPBDataTypeEnum:
        [(GPBEnumArray *) genericArray addRawValue:[ele intValue]];
        break;
      default:
        // todo:
        break;
    }
  }
}

+ (void)mergeMapField:(GPBFieldDescriptor *)field json:(id)json message:(GPBMessage *)msg {
  [self assert:json isKindOfClass:NSDictionary.class];
  id map = [msg valueForKey:field.name];
  GPBDataType valueDataType = field.dataType;
  for (NSString *key in json) {
    id val = json[key];
    switch (valueDataType) {
      case GPBDataTypeBytes:
      case GPBDataTypeString:
        [self assert:val isKindOfClass:NSString.class];
        [(NSMutableDictionary *) map setObject:[val copy] forKey:key];
        break;
      case GPBDataTypeMessage:
      case GPBDataTypeGroup: {
        [self assert:val isKindOfClass:NSDictionary.class];
        GPBMessage *message = [[field.msgClass alloc] init];
        [self merge:val message:message];
        [(NSMutableDictionary *) map setObject:message forKey:key];
        break;
      }
      case GPBDataTypeEnum:
//        [map setGPBGenericValue:&value forGPBGenericValueKey:&key];
        break;
      default:
        break;
    }
  }
}

+ (void)assert:(id)value isKindOfClass:(Class)clz {
  if (![value isKindOfClass:clz]) {
    [NSException raise:NSInvalidArgumentException format:@"Invalid %@ value: %@", NSStringFromClass(clz), value];
  }
}
@end