//
// Created by Larry Tin on 15/5/21.
//

#import <Foundation/Foundation.h>


@interface GDCTopicsManager : NSObject

- (void)addSubscribedTopic:(NSString *)topicFilter;

- (NSSet *)calculateTopicsToPublish:(NSString *)topicOfPublishMessage;

- (void)removeSubscribedTopic:(NSString *)topicFilter;

- (int)retainCountOfTopic:(NSString *)topicFilter;
@end