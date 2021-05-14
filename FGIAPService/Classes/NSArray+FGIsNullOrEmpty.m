//
//  NSArray+FGIsNullOrEmpty.m
//  FGIAPService
//
//  Created by FoneG on 2021/5/10.
//

#import "NSArray+FGIsNullOrEmpty.h"

@implementation NSArray (FGIsNullOrEmpty)

- (BOOL)FG_isNSStringAndNotEmpty
{
    if (nil == self) {
        return false;
    }
    if ([self isKindOfClass:[NSString class]]) {
        NSString *str = (NSString*)self;
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([str isEqualToString:@"<null>"]) {
            return false;
        }
        if ([str isEqualToString:@"(null)"]) {
            return false;
        }
        if (str.length == 0) {
            return false;
        }
        return true;
    } else if ([self isKindOfClass:[NSAttributedString class]]) {
        NSString *str = ((NSAttributedString *)self).string;
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (str.length > 0) {
            return true;
        }else{
            return false;
        }
    } else{
        return false;
    }
}


- (BOOL)FG_isNSArrayAndNotEmpty
{
    if ([self isKindOfClass:[NSArray class]]) {
        NSArray *temp = (NSArray *)self;
        if (temp.count > 0) {
            return true;
        }
    }
    return false;
}

- (BOOL)FG_isNSSetAndNotEmpty
{
    if ([self isKindOfClass:[NSSet class]]) {
        NSSet *temp = (NSSet *)self;
        if (temp.count > 0) {
            return true;
        }
    }
    return false;
}


@end
