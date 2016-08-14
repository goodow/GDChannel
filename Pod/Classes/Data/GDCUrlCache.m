//
// Created by Larry Tin on 8/14/16.
//

#import "GDCUrlCache.h"
#import "GPBMessage.h"
#import "FieldMask.pbobjc.h"

static NSString *const messageClass = @"messageClass";

static NSString *const dateFormat = @"EEEE, dd LLL yyyy hh:mm:ss zzz";

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
      _instance.dateFormatter.dateFormat = dateFormat;
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
  respHeaders[@"Last-Modified"] = [self.dateFormatter stringFromDate:[NSDate date]];
  NSURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:req.URL statusCode:200 HTTPVersion:nil headerFields:respHeaders];
  NSMutableDictionary *info = @{}.mutableCopy;
  info[messageClass] = NSStringFromClass(respMessage.class);
  NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:data userInfo:info storagePolicy:NSURLCacheStorageAllowed];

  [self.cache storeCachedResponse:cachedResponse forRequest:req];
}

- (nullable __kindof GPBMessage *)cachedMessageForPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys {
  NSURLRequest *req = [self requestForPath:path andRequest:reqMessage andKeys:keys];
  NSCachedURLResponse *cachedResponse = [self.cache cachedResponseForRequest:req];
  NSDictionary *info = cachedResponse.userInfo;
  GPBMessage *respMessage = [NSClassFromString(info[messageClass]) parseFromData:cachedResponse.data error:nil];
  return respMessage;
}

- (NSURLRequest *)requestForPath:(NSString *)path andRequest:(GPBMessage *)reqMessage andKeys:(GPBFieldMask *)keys {
  const NSString *domain = @"http://caching.gdc.goodow.com";
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