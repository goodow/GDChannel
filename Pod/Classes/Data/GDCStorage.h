//
// Created by Larry Tin on 15/12/8.
//

#import <Foundation/Foundation.h>

@protocol GDCMessage;

@interface GDCStorage : NSObject

@property(nonatomic, strong, readonly) NSCache *cache;

- (instancetype)initWithBaseDirectory:(NSString *)baseDir;

+ (NSDictionary *)mergeDictionaryRecursively:(NSDictionary *)original with:(NSDictionary *)change;

- (id <GDCMessage>)cache:(id <GDCMessage>)message;

- (void)save:(id <GDCMessage>)message;

- (id <GDCMessage>)get:(NSString *)topic;

- (void)remove:(NSString *)topic;
@end