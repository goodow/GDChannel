//
// Created by Larry Tin on 15/12/9.
//

#import <Foundation/Foundation.h>
#import "GDCEntry.h"
#import "GDCViewOptions.h"

@interface GDCOptions : GDCEntry

@property(nonatomic) BOOL retained;
@property(nonatomic) BOOL patch;
@property(nonatomic, strong) GDCViewOptions *viewOptions;
@property(nonatomic, strong) id extras;

+ (GDCOptions *)options;
@end