//
// Created by Larry Tin on 15/12/8.
//

#import <Foundation/Foundation.h>

@protocol GDCMessage;

@interface GDCStorage : NSObject

+ (GDCStorage *)instance;

- (instancetype)initWithBaseDirectory:(NSString *)baseDir;

- (void)cache:(NSString *)topic payload:(id)payload;

- (void)save:(id <GDCMessage>)message;

- (__kindof id)getPayload:(NSString *)topic;

- (id <GDCMessage>)getRetainedMessage:(NSString *)topic;

- (void)remove:(NSString *)topic;

+ (void)expandDictionary:(NSDictionary *)dict to:(NSMutableDictionary *)toRtn;

+ (NSDictionary *)flattedDictionary:(NSDictionary *)toFlat parentKey:(NSString *)parentKey;

+ (NSMutableDictionary *)mutableContainersAndLeaves:(NSDictionary *)dict;
@end