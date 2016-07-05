//
// Created by Larry Tin.
//

#import "GPBMessage.h"

@interface GPBMessage (JsonFormat)
/// Creates a new instance by parsing Json format. If
/// there is an error the method returns nil and the error is returned in
/// errorPtr (when provided).
///
/// @param json     The json to parse.
/// @param errorPtr An optional error pointer to fill in with a failure reason if
///                 the data can not be parsed.
///
/// @return A new instance of the class messaged.
+ (instancetype)parseFromJson:(NSDictionary *)json error:(NSError **)errorPtr;

- (instancetype)mergeFromJson:(NSDictionary *)json;

/// Serializes the message to Json.
///
/// If there is an error while generating the data, nil is returned.
///
/// @note This value is not cached, so if you are using it repeatedly, cache
///       it yourself.
- (nullable NSDictionary *)json;
@end