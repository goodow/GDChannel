//
// Created by Larry Tin on 15/5/21.
//

#import "GDCTopicsManager.h"


@implementation GDCTopicsManager {
  NSMutableDictionary *topicsRetainCounter;
  NSMutableDictionary *topicToPattern;
}
- (instancetype)init {
  self = [super init];
  if (self) {
    topicsRetainCounter = [NSMutableDictionary dictionary];
    topicToPattern = [NSMutableDictionary dictionary];
  }

  return self;
}

- (void)addSubscribedTopicFilter:(NSString *)topicFilter {
  topicsRetainCounter[topicFilter] = @([self retainCountOfTopic:topicFilter] + 1);
  NSString *pattern = topicFilter;
  if ([topicFilter isEqualToString:@"#"]) {
    pattern = @".*";
  } else {
    BOOL hasMultiLevelWildcard = [topicFilter hasSuffix:@"/#"];
    if (hasMultiLevelWildcard) {
      pattern = [topicFilter substringToIndex:topicFilter.length - 2];
    }
    static NSString *const singleLevelWildcardPattern = @"[^/]*";
    if ([pattern isEqualToString:@"+"]) {
      pattern = singleLevelWildcardPattern;
    } else {
      if ([pattern hasSuffix:@"/+"]) {
        pattern = [pattern stringByReplacingCharactersInRange:NSMakeRange(pattern.length - 1, 1) withString:singleLevelWildcardPattern];
      }
      if ([pattern hasPrefix:@"+/"]) {
        pattern = [pattern stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:singleLevelWildcardPattern];
      }
      for (NSRange range = [pattern rangeOfString:@"/+/"]; range.location != NSNotFound; range = [pattern rangeOfString:@"/+/"]) {
        range.location = range.location + 1;
        range.length = 1;
        pattern = [pattern stringByReplacingCharactersInRange:range withString:singleLevelWildcardPattern];
      }
    }
    if (hasMultiLevelWildcard) {
      pattern = [pattern stringByAppendingString:@"(/.*)?"];
    }
  }
  if (pattern != topicFilter) {
    pattern = [NSString stringWithFormat:@"^%@$", pattern];
    topicToPattern[topicFilter] = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
  }
}

- (NSSet *)calculateTopicFiltersToPublish:(NSString *)topic {
  NSMutableSet *matches = [NSMutableSet set];
  if (topicsRetainCounter[topic]) {
    [matches addObject:topic];
  }
  for (NSString *filter in topicToPattern) {
    NSTextCheckingResult *match = [topicToPattern[filter] firstMatchInString:topic options:0 range:NSMakeRange(0, topic.length)];
    if (match) {
      [matches addObject:filter];
    }
  }
  return matches;
}

- (void)removeSubscribedTopicFilter:(NSString *)topicFilter {
  int retain = [self retainCountOfTopic:topicFilter];
  if (retain == 1) {
    [topicsRetainCounter removeObjectForKey:topicFilter];
  } else {
    topicsRetainCounter[topicFilter] = @(retain - 1);
  }
}

- (int)retainCountOfTopic:(NSString *)topicFilter {
  return [topicsRetainCounter[topicFilter] intValue];
}
@end