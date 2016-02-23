//if (window.GDCWebViewJavascriptBus) {
//    return;
//}

var realtime = realtime || {};
realtime.channel = realtime.channel || {};
realtime.channel.Bus = function() {
    var self = this;
    // attributes
    this.state = realtime.channel.Bus.CONNECTING;
    this.topicPrefix = 'JAVASCRIPT_TOPIC_PREFIX';
    this.handlers = {};
    this.replyHandlers = {};

    // default event handlers
    this.onerror = function (err) {
        try {
            console.error(err);
        } catch (e) {
            // dev tools are disabled so we cannot use console on IE
        }
    };
    this.onopen = null;

    function sendOrPub(send, local, topic, payload, options, replyHandler) {
        checkOpen();
        if (typeof options === 'function') {
            replyHandler = options;
            options = null;
        }

        var msg = {};
        msg["type"] = send ? "send" : "publish";
        msg["topic"] = topic;
        if (send) {
            msg["send"] = true;
        }
        if (local) {
            msg["local"] = true;
        }
        if (payload) {
            msg["payload"] = payload;
        }
        if (options) {
            msg["options"] = options;
        }
        if (send && replyHandler) {
            var replyTopic = makeUUID(topic);
            msg["replyTopic"] = replyTopic;
            self.replyHandlers[replyTopic] = replyHandler;
        }
        _doSend(msg);
    }

    function doSubscribe(local, topic, handler) {
        checkOpen();
        // ensure it is an array
        if (!self.handlers[topic]) {
            self.handlers[topic] = [];
            // First handler for this address so we should register the connection
            var msg = {};
            msg["type"] = "subscribe";
            msg["topic"] = topic;
            if (local) {
                msg["local"] = true;
            }
            _doSend(msg);
        }
        self.handlers[topic].push(handler);

        var unsubscribe = function() {
            checkOpen();
            var handlers = self.handlers[topic];
            if (handlers) {
                var idx = handlers.indexOf(handler);
                if (idx != -1) {
                    handlers.splice(idx, 1)
                }
                if (handlers.length == 0) {
                    // No more local handlers so we should unregister the connection
                    var msg = {};
                    msg["type"] = "unsubscribe";
                    msg["topic"] = topic;
                    if (local) {
                        msg["local"] = true;
                    }
                    _doSend(msg);
                    delete self.handlers[topic];
                }
            }
        };
        return {unsubscribe: unsubscribe};
    }

    // are we ready?
    function checkOpen() {
        if (state != realtime.channel.Bus.OPEN) {
            throw new Error('GDCWebViewJavascriptBus: INVALID_STATE_ERR');
        }
    }
}

realtime.channel.Bus.prototype.send = function(topic, payload, options, replyHandler) {
    sendOrPub(true, false, topic, payload, options, replyHandler)
};
realtime.channel.Bus.prototype.sendLocal = function(topic, payload, options, replyHandler) {
    sendOrPub(true, true, topic, payload, options, replyHandler)
};
realtime.channel.Bus.prototype.publish = function(topic, payload, options) {
    sendOrPub(false, false, topic, payload, options, null)
};
realtime.channel.Bus.prototype.publishLocal = function(topic, payload, options) {
    sendOrPub(false, true, topic, payload, options, null)
};
realtime.channel.Bus.prototype.subscribe = function(topic, handler) {
    return doSubscribe(false, topic, handler);
}
realtime.channel.Bus.prototype.subscribeLocal = function(topic, handler) {
    return doSubscribe(true, topic, handler);
}

function makeUUID(topic) {
    var id = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (a, b) {
        return b = Math.random() * 16, (a == 'y' ? b & 3 | 8 : b | 0).toString(16);
    });
    return "reply/" + id + "/" + topic;
}
realtime.channel.Bus.CONNECTING = 0;
realtime.channel.Bus.OPEN = 1;
realtime.channel.Bus.CLOSING = 2;
realtime.channel.Bus.CLOSED = 3;

window.bus = window.GDCWebViewJavascriptBus = new realtime.channel.Bus();
window.bus.state = realtime.channel.Bus.OPEN;

var messagingIframe;
var sendMessageQueue = [];
var CUSTOM_PROTOCOL_SCHEME = 'wvjbscheme';
var QUEUE_HAS_MESSAGE = '__WVJB_QUEUE_MESSAGE__';

function _doSend(message, responseCallback) {
    sendMessageQueue.push(message);
    messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
}

realtime.channel.Bus.prototype._fetchQueue = function() {
    var messageQueueString = JSON.stringify(sendMessageQueue);
    sendMessageQueue = [];
    return messageQueueString;
}

realtime.channel.Bus.prototype._handleMessageFromObjC = function(messageJSON) {
    setTimeout(function _timeoutDispatchMessageFromObjC() {
        var message = JSON.parse(messageJSON);
        // define a reply function on the message itself
        var replyTopic = message["replyTopic"];
        if (replyTopic) {
            Object.defineProperty(message, 'reply', {
                value: function (payload, replyHandler) {
                    if (message["local"]) {
                        self.sendLocal(replyTopic, payload, replyHandler);
                    } else {
                        self.send(replyTopic, payload, replyHandler);
                    }
                }
            });
        }

        var topic = message["topic"];
        if (self.handlers[topic]) {
            // iterate all registered handlers
            var handlers = self.handlers[topic];
            for (var i = 0; i < handlers.length; i++) {
                handlers[i](message);
            }
        } else if (self.replyHandlers[topic]) {
            // Might be a reply message
            var handler = self.replyHandlers[topic];
            delete self.replyHandlers[topic];
            var error = message["error"];
            handler({"failed": error ? ture : false, "cause": error, "result": message});
        } else {
            if (json.type === 'err') {
                self.onerror(message);
            } else {
                try {
                    console.warn('No handler found for message: ', message);
                } catch (e) {
                    // dev tools are disabled so we cannot use console on IE
                }
            }
        }
    });
}

messagingIframe = document.createElement('iframe');
messagingIframe.style.display = 'none';
messagingIframe.src = CUSTOM_PROTOCOL_SCHEME + '://' + QUEUE_HAS_MESSAGE;
document.documentElement.appendChild(messagingIframe);

function setupWebViewJavascriptBridge(callback) {
    if (window.GDCWebViewJavascriptBus) {
        return callback(GDCWebViewJavascriptBus);
    }
}

setupWebViewJavascriptBridge(function (bus) {
    // 兼容旧接口
    if (window.TenvideoJSBridge) {
        return;
    }
    window.alert('jbjb');
    var bridge = {};
    window.TenvideoJSBridge = bridge;
    bridge.on = function(topic, callback) {
        return bus.subscribeLocal(bus.topicPrefix + topic, function(message) {
            callback(message.payload);
        });
    };
    bridge.invoke = function(topic, payload, callback) {
        bus.sendLocal(bus.topicPrefix + topic, payload, function(asyncResult) {
            if (asyncResult.failed) {
                callback({"errCode": asyncResult.cause.code, "errMsg": asyncResult.cause, "result": null});
            } else {
                var message = asyncResult.result;
                callback({"errCode": 0, "errMsg": null, "result": message.payload});
            }
        });
    };
    var readyEventExt = document.createEvent('Events');
    readyEventExt.initEvent('onTenvideoJSBridgeReady');
    readyEventExt.bridge = bridge;
    document.dispatchEvent(readyEventExt);
});