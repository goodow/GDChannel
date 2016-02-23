// This file contains the source for the Javascript side of the
// WebViewJavascriptBridge. It is plaintext, but converted to an NSString
// via some preprocessor tricks.
//
// Previous implementations of WebViewJavascriptBridge loaded the javascript source
// from a resource. This worked fine for app developers, but library developers who
// included the bridge into their library, awkwardly had to ask consumers of their
// library to include the resource, violating their encapsulation. By including the
// Javascript as a string resource, the encapsulation of the library is maintained.

#import "QQLJavascriptBridge_js.h"

NSString * QQLJavascriptBridge_js() {
	#define __wvjb_js_func__(x) #x
	
	// BEGIN preprocessorJSCode
	static NSString * preprocessorJSCode = @__wvjb_js_func__(
;(function() {
    window.alert('aa22');
    if (window.TenvideoJSBridge) {
			return;
		}

		function setupWebViewJavascriptBridge(callback) {
			window.alert('bbbbb');
			if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
			if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
			window.WVJBCallbacks = [callback];
			var WVJBIframe = document.createElement('iframe');
			WVJBIframe.style.display = 'none';
			WVJBIframe.src = 'wvjbscheme://__BRIDGE_LOADED__';
			document.documentElement.appendChild(WVJBIframe);
			setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
		}

		setupWebViewJavascriptBridge(function(bridge) {
			/* Initialize your app here */

			// JSBridge框架接口扩展，多平台统一接口，tencent:jiachunke(20150328)
			if (window.TenvideoJSBridge) {
				return;
			}
			window.TenvideoJSBridge = bridge;
			window.TenvideoJSBridge.on = bridge.registerHandler;
			window.TenvideoJSBridge.invoke = bridge.callHandler;
			window.bus = {};
			window.bus.send = function(topic, payload, options, replyHandler) {
				bridge.callHandler(topic, payload, function responseCallback(responseData) {
					var asyncResult = {"failed": false, "result": {"payload": responseData}};
					replyHandler(asyncResult);
				});
			};
			window.bus.publish = function(topic, payload, options) {
				bridge.callHandler(topic, payload);
			};
			window.bus.subscribe = function(topic, handler) {
				bridge.registerHandler(topic, function(data, responseCallback) {
					var message = {"topic": topic, "payload": data};
					message.reply = function(payload, replyHandler) {
						responseCallback(payload);
					};
					handler(message);
				});
			};

			var doc = document
			// 先dispatch新事件，tencent:jiachunke(20150408)
			// JSBridge框架接口扩展，多平台统一接口，tencent:jiachunke(20150328)
			var readyEventExt = doc.createEvent('Events')
			readyEventExt.initEvent('onTenvideoJSBridgeReady')
			readyEventExt.bridge = TenvideoJSBridge
			doc.dispatchEvent(readyEventExt)
		})
})();
	); // END preprocessorJSCode

	#undef __wvjb_js_func__
	return preprocessorJSCode;
};