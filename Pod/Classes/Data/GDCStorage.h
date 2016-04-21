//
// Created by Larry Tin on 15/12/8.
//

#import <Foundation/Foundation.h>

@protocol GDCMessage;

@interface GDCStorage : NSObject

+ (GDCStorage *)instance;

+ (BOOL)patchRecursively:(id)original with:(id)patch;
+ (NSDictionary *)flattedDictionary:(NSDictionary *)toFlat parentKey:(NSString *)parentKey;
- (instancetype)initWithBaseDirectory:(NSString *)baseDir;

- (void)cache:(NSString *)topic payload:(id)payload;

- (void)save:(id <GDCMessage>)message;

- (id)getPayload:(NSString *)topic;

- (id <GDCMessage>)getRetainedMessage:(NSString *)topic;

- (void)remove:(NSString *)topic;
@end