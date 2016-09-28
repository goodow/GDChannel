//
// Created by Larry Tin on 15/12/9.
//

#import <Foundation/Foundation.h>
#import "GDCSerializable.h"

enum GDCQualityOfService {
  GDCQosAtMostOnce, GDCQosAtLeastOnce, GDCQosExactlyOnce
};

@interface GDCOptions : NSObject <GDCSerializable>

- (GDCOptions *(^)(BOOL retained))retained;

- (GDCOptions *(^)(BOOL patch))patch;

/**
 * Set the send timeout.
 *
 * @param timeout  the timeout value, in ms.
 */
- (GDCOptions *(^)(long timeout))timeout;

- (GDCOptions *(^)(enum GDCQualityOfService qos))qos;

- (GDCOptions *(^)(NSObject <GDCSerializable> *extras))extras;

@end