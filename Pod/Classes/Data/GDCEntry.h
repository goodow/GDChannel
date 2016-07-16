//
// Created by Larry Tin on 15/12/8.
// Copyright (c) 2015 Larry Tin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "GDCSerializable.h"

@class GDCOptions;

static NSString *const watchChanges = @"_watch";

@protocol GDCEntry <MTLModel>
@end

@interface GDCEntry : MTLModel <GDCEntry, GDCSerializable>

- (void)addTopic:(NSString *)topic options:(GDCOptions *)options;

@end