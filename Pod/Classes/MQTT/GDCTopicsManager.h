//
// Created by Larry Tin on 15/5/21.
//

#import <Foundation/Foundation.h>


@interface GDCTopicsManager : NSObject

- (void)addSubscribedTopicFilter:(NSString *)topicFilter;

- (NSSet *)calculateTopicFiltersToPublish:(NSString *)topic;

- (void)removeSubscribedTopicFilter:(NSString *)topicFilter;

- (int)retainCountOfTopic:(NSString *)topicFilter;
@end