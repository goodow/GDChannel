//
// Created by Larry Tin on 2017/6/11.
//

#import "GDCFirebaseChannel.h"
#import "Firebase.h"
#import "GDCBusProvider.h"
#import "GDCMessageImpl.h"
#import "NSObject+GDChannel.h"

@interface GDCFirebaseChannel ()
@property NSString *clientId;
@property FIRDatabaseReference *bufRef;
@property NSMutableDictionary<NSString *, NSString *> *replyTopics;
@property(nonatomic, strong) FIRDatabaseReference *toRemoveRef;
@end

@implementation GDCFirebaseChannel {

}
- (instancetype)initWithClientId:(NSString *)clientId {
  self = [super init];
  if (self) {
    _clientId = clientId;
    _bufRef = [FIRDatabase.database referenceWithPath:@"bus"];
    _replyTopics = @{}.mutableCopy;

    __weak GDCFirebaseChannel *weakSelf = self;
    _toRemoveRef = [[_bufRef child:@"queue"] child:clientId];
    [_toRemoveRef observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) {
        [snapshot.ref onDisconnectRemoveValue];
        NSDictionary *msg = snapshot.value;
        NSString *topic = [clientId stringByAppendingPathComponent:msg[topicKey]];
        id payload = msg[payloadKey];
        GDCOptions *options = [GDCOptions parseFromJson:msg[optionsKey] error:nil];
        [weakSelf.bus sendLocal:topic payload:payload options:options replyHandler:^(id <GDCAsyncResult> asyncResult) {
            GDCMessageImpl *msg = asyncResult.result;
            NSDictionary *reply = [msg toJsonWithTopic:NO];
            [[snapshot.ref child:@"reply"] setValue:reply];
        }];
    }];
  }

  return self;
}

- (void)dealloc {
  [_toRemoveRef removeAllObservers];
}

- (void)goOnline:(id)clientInfo {
  FIRDatabaseReference *clientIdRef = [[self.bufRef child:@"clients"] child:self.clientId];
  [[FIRDatabase.database referenceWithPath:@".info/connected"] observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
      if ([snapshot.value boolValue]) {
        [clientIdRef onDisconnectRemoveValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *ref) {
            if (error) {
              return;
            }
            [clientIdRef setValue:clientInfo];
        }];
      }
  }];
}

- (void)reportMessage:(GDCMessageImpl *)message {
  if (message.payload && (
      ![message.payload conformsToProtocol:@protocol(GDCSerializable)] && ![message.payload isKindOfClass:NSString.class] &&
          ![message.payload isKindOfClass:NSNumber.class] && ![message.payload isKindOfClass:NSArray.class] && ![message.payload isKindOfClass:NSDictionary.class])) {
    return;
  }
  NSString *topic = message.topic;
  NSString *historyPath = nil;
  if ([topic hasPrefix:@"reply/"]) {
    if (!self.replyTopics[topic]) {
      return;
    }
    historyPath = self.replyTopics[topic];
    [self.replyTopics removeObjectForKey:topic];
    NSMutableDictionary *value = [message toJsonWithTopic:NO];
    value[topicKey] = nil;
    [[[self.bufRef child:historyPath] child:@"reply"] setValue:value];
    return;
  }
  if ([topic hasPrefix:[GDCBusProvider.clientId stringByAppendingString:@"/"]]) {
    topic = [topic substringFromIndex:GDCBusProvider.clientId.length + 1];
  }
  NSRange range = [topic rangeOfString:@"/"];
  NSUInteger index = range.location;
  if (index == NSNotFound) {
    return;
  }

  historyPath = [NSString stringWithFormat:@"history/%@/messages/", [topic stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
  FIRDatabaseReference *historyRef = [self.bufRef child:historyPath].childByAutoId;
  historyPath = [historyPath stringByAppendingPathComponent:historyRef.key];
  if (message.replyTopic) {
    self.replyTopics[message.replyTopic] = historyPath;
  }
  NSMutableDictionary *msg = [message toJsonWithTopic:NO];
  msg[@"client"] = self.clientId;
  msg[topicKey] = topic;
  msg[replyTopicKey] = nil;
  msg[@"time"] = FIRServerValue.timestamp;

  NSMutableDictionary *values = @{}.mutableCopy;
  values[historyPath] = msg;

  NSString *categoryPath = @"category";
  NSMutableDictionary *categoryValue = @{}.mutableCopy;
  categoryPath = [NSString stringWithFormat:@"%@/%@/topics/%@", categoryPath, [topic substringToIndex:index],
                                            [[topic substringFromIndex:index + 1] stringByReplacingOccurrencesOfString:@"/" withString:@"_"]];
  categoryValue[@"version"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  values[categoryPath] = categoryValue;

  [self.bufRef updateChildValues:values];
}
@end