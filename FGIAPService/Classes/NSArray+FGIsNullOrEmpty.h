//
//  NSArray+FGIsNullOrEmpty.h
//  FGIAPService
//
//  Created by FoneG on 2021/5/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (FGIsNullOrEmpty)

- (BOOL)FG_isNSStringAndNotEmpty;

- (BOOL)FG_isNSArrayAndNotEmpty;

- (BOOL)FG_isNSSetAndNotEmpty;
@end

NS_ASSUME_NONNULL_END
