#import "GDCJavascriptBridgeBus.h"
#import "GDCMessageImpl.h"
#import "GDCNotificationBus.h"
#import "GDCAsyncResultImpl.h"
#import "GDCBusProvider.h"

@interface GDCJavascriptBridgeBus ()
@property(nonatomic, readonly, strong) id <GDCBus> baseBus;
@end

@implementation GDCJavascriptBridgeBus

+ (NSString *)topicPrefix {
  return [[GDCBusProvider clientId:nil] stringByAppendingPathComponent:@"jsBridge/"];
}

- (instancetype)initWithWebView:(NSString *)webView bus:(id <GDCBus>)bus {
  self = [super init];
  if (self) {
    _baseBus = bus ?: [[GDCNotificationBus alloc] init];
    _bridge = [WebViewJavascriptBridge bridgeForWebView:webView];
  }
  return self;
}

- (instancetype)init {
  @throw [NSException exceptionWithName:@"Singleton"
                                 reason:[NSString stringWithFormat:@"Use %@ %@", NSStringFromClass(GDCJavascriptBridgeBus.class), NSStringFromSelector(@selector(initWithWebView:bus:))]
                               userInfo:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload {
  return [self publish:topic payload:payload options:nil];
}

- (id <GDCBus>)publish:(NSString *)topic payload:(id)payload options:(GDCOptions *)options {
  [self.baseBus publish:topic payload:payload options:options];
  return self;
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload {
  return [self publishLocal:topic payload:payload options:nil];
}

- (id <GDCBus>)publishLocal:(NSString *)topic payload:(id)payload options:(GDCOptions *)options {
  return [self sendLocal:topic payload:payload options:options replyHandler:nil];
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self send:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)send:(NSString *)topic payload:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  [self.baseBus send:topic payload:payload options:options replyHandler:replyHandler];
  return self;
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload replyHandler:(GDCAsyncResultBlock)replyHandler {
  return [self sendLocal:topic payload:payload options:nil replyHandler:replyHandler];
}

- (id <GDCBus>)sendLocal:(NSString *)topic payload:(id)payload options:(GDCOptions *)options replyHandler:(GDCAsyncResultBlock)replyHandler {
  if (!replyHandler) {
    [self.bridge callHandler:topic data:payload];
  } else {
    NSString *replyTopic = [GDCMessageImpl generateReplyTopic:topic];
    __block id <GDCMessageConsumer> consumer = [self.baseBus subscribeLocal:replyTopic handler:^(id <GDCMessage> message) {
        [consumer unsubscribe];
        GDCAsyncResultImpl *asyncResult = [[GDCAsyncResultImpl alloc] initWithMessage:message];
        replyHandler(asyncResult);
    }];
    __weak GDCJavascriptBridgeBus *weakSelf = self;
    [self.bridge callHandler:topic data:payload responseCallback:^(id responseData) {
        [weakSelf.baseBus publishLocal:replyTopic payload:responseData options:options];
    }];
  }

  return self;
}

- (id <GDCMessageConsumer>)subscribe:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  return [self.baseBus subscribe:topicFilter handler:handler];
}

- (id <GDCMessageConsumer>)subscribeLocal:(NSString *)topicFilter handler:(GDCMessageBlock)handler {
  __weak GDCJavascriptBridgeBus *weakSelf = self;
  [self.bridge registerHandler:topicFilter handler:^(id data, WVJBResponseCallback responseCallback) {
      [weakSelf.baseBus sendLocal:topicFilter payload:data replyHandler:^(id <GDCAsyncResult> asyncResult) {
          responseCallback(asyncResult.failed ? asyncResult.cause : asyncResult.result.payload);
      }];
  }];

  return [self.baseBus subscribeLocal:topicFilter handler:handler];
}

@end