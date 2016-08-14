//
// Created by Larry Tin on 8/14/16.
//

#import <Foundation/Foundation.h>

@class GPBMessage;
@class GPBFieldMask;


@interface GDCUrlCache : NSObject
+ (GDCUrlCache *)instance;

- (void)storeCachedMessage:(GPBMessage *)respMessage forPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys withMaxAge:(int)maxAge;

- (GPBMessage *)cachedMessageForPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys;
@end