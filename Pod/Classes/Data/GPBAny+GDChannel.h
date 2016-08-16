//
// Created by Larry Tin on 16/8/8.
//

#import <Foundation/Foundation.h>
#import "Any.pbobjc.h"

@protocol GDCSerializable;

@interface GPBAny (GDChannel)

+ (instancetype)pack:(id)value withTypeUrlPrefix:(NSString *)typeUrlPrefix;

- (__kindof id)unpack;

+ (id)packToJson:(id <GDCSerializable>)value;

+ (__kindof id)unpackFromJson:(id)json error:(NSError **)errorPtr;
@end