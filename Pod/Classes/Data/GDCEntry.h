//
// Created by Larry Tin on 15/12/8.
// Copyright (c) 2015 Larry Tin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"

@protocol GDCEntry <MTLModel>
@end

@interface GDCEntry : MTLModel <GDCEntry>
+ (instancetype)of:(id)payload;

- (NSDictionary *)toDictionary;

@end