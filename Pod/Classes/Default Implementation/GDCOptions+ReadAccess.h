//
// Created by Larry Tin on 16/9/27.
//

#import <Foundation/Foundation.h>
#import "GDCOptions.h"

@interface GDCOptions (ReadAccess)

- (BOOL)isRetained;
- (BOOL)isPatch;
- (long)getTimeout;
- (enum GDCQualityOfService) getQos;
- (__kindof NSObject <GDCSerializable> *)getExtras;

@end