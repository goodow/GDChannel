//
// Created by Larry Tin on 15/12/29.
// Copyright (c) 2015 Larry Tin. All rights reserved.
//

#import "GDCTestEntry.h"
#import "MTLJSONAdapter.h"
#import "GDCSampleEntry.h"


@implementation GDCTestEntry {

}

+ (NSValueTransformer *)entryListJSONTransformer {
  return [MTLJSONAdapter arrayTransformerWithModelClass:GDCSampleEntry.class];
}
@end