//
// Created by Larry Tin.
//

#import "GPBMessage.h"
#import "GDCSerializable.h"

@interface GPBMessage (JsonFormat) <GDCSerializable>

+ (NSDictionary *)printMessage:(GPBMessage *)msg useTextFormatKey:(BOOL)useTextFormatKey;

@end