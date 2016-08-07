//
// Created by Larry Tin on 15/12/9.
//

#import <Foundation/Foundation.h>
#import "GDCEntry.h"

enum GDCQualityOfService {
    AtMostOnce, AtLeastOnce, ExactlyOnce
};
@interface GDCOptions : NSObject <GDCSerializable>

@property(nonatomic) BOOL retained;
@property(nonatomic) BOOL patch;
/**
 * Set the send timeout.
 *
 * @param timeout  the timeout value, in ms.
 */
@property(nonatomic) long timeout;
@property(nonatomic) enum GDCQualityOfService qos;
@property(nonatomic, strong) __kindof NSObject <GDCSerializable> *extras;

+ (GDCOptions *)optionWithExtras:(NSObject <GDCSerializable> *)extras;

@end