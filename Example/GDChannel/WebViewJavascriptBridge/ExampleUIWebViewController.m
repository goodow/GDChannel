//
//  ExampleUIWebViewController.m
//  ExampleApp-iOS
//
//  Created by Marcus Westin on 1/13/14.
//  Copyright (c) 2014 Marcus Westin. All rights reserved.
//

#import "ExampleUIWebViewController.h"
#import "WebViewJavascriptBridge.h"
#import "GDCJavascriptBridgeBus.h"
#import "GDCBusProvider.h"
#import "QQLJavascriptBridge_JS.h"

@interface ExampleUIWebViewController () <UIWebViewDelegate>
@property GDCJavascriptBridgeBus* jsBus;
@end

@implementation ExampleUIWebViewController

- (void)viewWillAppear:(BOOL)animated {
    [WebViewJavascriptBridge enableLogging];
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    self.jsBus = [[GDCJavascriptBridgeBus alloc] initWithWebView:webView bus:GDCBusProvider.instance];
    [self.jsBus.bridge setWebViewDelegate:self];

    [self.jsBus subscribeLocal:@"sometopic1" handler:^(id <GDCMessage> message) {
        [message reply:@{@"xxii": @33}];
    }];

    [self renderButtons:webView];
    [self loadExamplePage:webView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"webViewDidStartLoad");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad");
    NSString *js = QQLJavascriptBridge_js();
    [self.jsBus.bridge _evaluateJavascript:js];
}

- (void)renderButtons:(UIWebView*)webView {
    UIFont* font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
    
    UIButton *callbackButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [callbackButton setTitle:@"Call handler" forState:UIControlStateNormal];
    [callbackButton addTarget:self action:@selector(callHandler:) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:callbackButton aboveSubview:webView];
    callbackButton.frame = CGRectMake(10, 400, 100, 35);
    callbackButton.titleLabel.font = font;
    
    UIButton* reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"Reload webview" forState:UIControlStateNormal];
    [reloadButton addTarget:webView action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
    [self.view insertSubview:reloadButton aboveSubview:webView];
    reloadButton.frame = CGRectMake(110, 400, 100, 35);
    reloadButton.titleLabel.font = font;
}

- (void)callHandler:(id)sender {
    [self.jsBus sendLocal:@"sometopic2" payload:@{@"key":@4447} replyHandler:^(id <GDCAsyncResult> asyncResult) {
        id <GDCMessage> msg = asyncResult.result;
        [msg reply:@"key-reply"];
    }];
}

- (void)loadExamplePage:(UIWebView*)webView {
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"jsBridge" ofType:@"html"];
    NSString* appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:
        [NSString stringWithFormat:@"%@",
                                   [[NSBundle mainBundle] bundlePath]]];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}
@end
