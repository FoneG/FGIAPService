//
//  NSObject+FGIsNullOrEmpty.m
//  FGIAPService
//
//  Created by FoneG on 2021/5/10.
//

#import "NSObject+FGIsNullOrEmpty.h"

@implementation NSObject (FGIsNullOrEmpty)

- (BOOL)isNSStringAndNotEmpty
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


- (BOOL)isNSArrayAndNotEmpty
{
    if ([self isKindOfClass:[NSArray class]]) {
        NSArray *temp = (NSArray *)self;
        if (temp.count > 0) {
            return true;
        }
    }
    return false;
}

@end
