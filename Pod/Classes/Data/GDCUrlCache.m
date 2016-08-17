//
// Created by Larry Tin on 8/14/16.
//

#import "GDCUrlCache.h"
#import "GPBMessage.h"
#import "FieldMask.pbobjc.h"

static NSString *const kMessageClassKey = @"messageClass";
static NSString *const kMaxAgeKey = @"magAge";
static NSString *const kDateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
static NSString *const kDateHeaderName = @"Date";

@interface GDCUrlCache ()
@property(nonatomic) NSURLCache *cache;
@property(nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation GDCUrlCache {
}
+ (GDCUrlCache *)instance {
  static GDCUrlCache *_instance = nil;

  @synchronized (self) {
    if (_instance == nil) {
      _instance = [[self alloc] init];
      _instance.cache = [NSURLCache sharedURLCache];
      _instance.dateFormatter = [[NSDateFormatter alloc] init];
      _instance.dateFormatter.dateFormat = kDateFormat;
    }
  }

  return _instance;
}

- (void)storeCachedMessage:(GPBMessage *)respMessage forPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys withMaxAge:(int)maxAge {
  NSURLRequest *req = [self requestForPath:path andRequest:reqMessage andKeys:keys];

  NSData *data = respMessage.data;
  NSMutableDictionary<NSString *, NSString *> *respHeaders = @{}.mutableCopy;
  respHeaders[@"Cache-Control"] = [NSString stringWithFormat:@"max-age=%d", maxAge];
  respHeaders[@"Content-Length"] = @(data.length).stringValue;
  respHeaders[kDateHeaderName] = [self.dateFormatter stringFromDate:[NSDate date]];
  NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:req.URL statusCode:200 HTTPVersion:(__bridge NSString *) kCFHTTPVersion1_1 headerFields:respHeaders];
  NSMutableDictionary *info = @{}.mutableCopy;
  info[kMessageClassKey] = NSStringFromClass(respMessage.class); // 转换成string, 否则应用下次启动后取出的userInfo变为nil
  info[kMaxAgeKey] = @(maxAge);
  NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:info storagePolicy:NSURLCacheStorageAllowed];

  [self.cache storeCachedResponse:cachedResponse forRequest:req];
}

- (nullable __kindof GPBMessage *)cachedMessageForPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys expired:(BOOL *)expired {
  NSURLRequest *req = [self requestForPath:path andRequest:reqMessage andKeys:keys];
  NSCachedURLResponse *cachedResponse = [self.cache cachedResponseForRequest:req];
  if (!cachedResponse) {
    return nil;
  }
  NSDictionary *info = cachedResponse.userInfo;
  if (expired && info) {
    NSString *dateStr = ((NSHTTPURLResponse *) cachedResponse.response).allHeaderFields[kDateHeaderName];
    NSDate *date = [self.dateFormatter dateFromString:dateStr];
    int maxAge = [info[kMaxAgeKey] intValue];
    *expired = [[NSDate date] timeIntervalSinceDate:date] > maxAge;
  }

  return [NSClassFromString(info[kMessageClassKey]) parseFromData:cachedResponse.data error:nil];
}

- (NSURLRequest *)requestForPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys {
  const NSString *domain = @"https://caching.gdc.goodow.com";
  NSMutableString *paths = path.mutableCopy;
  for (NSString *path in keys.pathsArray) {
    id val = [reqMessage valueForKeyPath:path];
    [paths appendFormat:@"/%@/%@", path, val];
  }
  NSURL *url = [NSURL URLWithString:[domain stringByAppendingPathComponent:paths]];
  NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:url];
  return req;
}

@end