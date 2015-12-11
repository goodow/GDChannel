//
// Created by Larry Tin on 15/12/9.
//

#import <Foundation/Foundation.h>
#import "GDCEntry.h"
#import "GDCViewOptions.h"

@interface GDCOptions : GDCEntry

@property(nonatomic) BOOL retained;
@property(nonatomic) BOOL patch;
// 若希望订阅者接收到的是强类型, 则指定类型名
@property(nonatomic) NSString *type;
@property(nonatomic, strong) GDCViewOptions *viewOptions;
@property(nonatomic, strong) id extras;

+ (GDCOptions *)createWithViewOptions;

@end