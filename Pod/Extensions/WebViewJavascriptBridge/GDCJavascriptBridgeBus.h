#import <Foundation/Foundation.h>
#import "GDCBus.h"
#import "WebViewJavascriptBridge.h"

@interface GDCJavascriptBridgeBus : NSObject <GDCBus>
@property(nonatomic, readonly, strong) WebViewJavascriptBridge *bridge;

+ (NSString *)topicPrefix;

- (instancetype)initWithWebView:(UIWebView *)webView bus:(id <GDCBus>)bus;
@end
