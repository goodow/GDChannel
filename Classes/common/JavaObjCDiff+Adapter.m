// Copyright 2014 Goodow.com. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  JavaObjCDiff+Adapter.m
//  GDChannel
//
//  Created by Larry Tin.
//

#import "JavaObjCDiff+Adapter.h"
#import "java/lang/RuntimeException.h"
#import "Google-Diff-Match-Patch/DiffMatchPatch.h"

@implementation ComGoodowRealtimeObjcObjCDiff (Adapter)

- (void)diff:(NSString *)before after:(NSString *)after target:(id <ComGoodowRealtimeCoreDiff_ListTarget>)target {
  DiffMatchPatch *dmp = [DiffMatchPatch new];
  NSMutableArray * diffs = [dmp diff_mainOfOldString:before andNewString:after];
  if(!diffs || [diffs count] == 0){
    return;
  }
  [dmp diff_cleanupSemantic:diffs];
  int cursor = 0;
  for(Diff *diff in diffs){
    NSString *text = diff.text;
    int len = (int)text.length;
    switch (diff.operation) {
      case DIFF_EQUAL:
        cursor += len;
        break;
      case DIFF_INSERT:
        [target insertWithInt:cursor withId:text];
        cursor += len;
        break;
      case DIFF_DELETE:
        [target removeWithInt:cursor withInt:len];
        break;
      default:
        @throw [[JavaLangRuntimeException alloc] initWithNSString:@"Shouldn't reach here!"];
    }
  }
}


@end