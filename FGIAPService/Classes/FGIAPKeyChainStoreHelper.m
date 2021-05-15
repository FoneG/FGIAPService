//
//  FGIAPProductKeyChainStore.m
//  MaltBaby
//
//  Created by FoneG on 2020/5/8.
//

#import "FGIAPKeyChainStoreHelper.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "FGIAPServiceUtility.h"
#import "NSObject+FGIsNullOrEmpty.h"

static NSString *FGIAPProductKeyChainStoreService = @"__FGIAPProductKeyChainStore__";

@interface FGIAPKeyChainStoreHelper ()
@property (nonatomic, strong) UICKeyChainStore *store;
@end

@implementation FGIAPKeyChainStoreHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.store = [UICKeyChainStore keyChainStoreWithService:FGIAPProductKeyChainStoreService];
                
        NSArray *allitems = [self.store allItems];
        [allitems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] && [[obj valueForKey:@"value"] isKindOfClass:[NSString class]]) {
                if ( [[obj valueForKey:@"value"] containsString:@"&"]) {
                    NSArray *components = [[obj valueForKey:@"value"] componentsSeparatedByString:@"&"];
                    NSString *newValue = [NSString stringWithFormat:@"%@&%@", components.firstObject?:@"", @"0"];
                    [self.store setString:newValue forKey:[obj valueForKey:@"key"]];
                }
            }
        }];
    }
    return self;
}

- (void)update:(NSString *)orderId product:(NSString *)productIdentifier{
    if ([orderId FG_isNSStringAndNotEmpty] && [productIdentifier FG_isNSStringAndNotEmpty]) {
        /// 0代表未处理
        NSString *value = [NSString stringWithFormat:@"%@&%@", productIdentifier, @"0"];
        [self.store setString:value forKey:orderId];
    }
    FGLog(@"@@## FGIAPProductKeyChainStore update orderId: %@ productIdentifier:%@",  orderId, productIdentifier);
}
- (NSString *)requestOneOrderWithProduct:(NSString *)productIdentifier{
    
    if ([productIdentifier FG_isNSStringAndNotEmpty]) {
        NSString *value = [NSString stringWithFormat:@"%@&%@", productIdentifier, @"0"];
        __block NSDictionary *one = nil;
        [[self.store allItems] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] && [[obj valueForKey:@"value"] isKindOfClass:[NSString class]]) {
                if ([[obj valueForKey:@"value"] isEqualToString:value]) {
                    one = obj;
                    *stop = YES;
                }
            }
        }];
        NSString *key = one?[one valueForKey:@"key"]:nil;
        if ([key FG_isNSStringAndNotEmpty]) {
            NSString *newValue = [NSString stringWithFormat:@"%@&%@", productIdentifier, @"1"];
            [self.store setString:newValue forKey:key];
        }
        return key;
    }
    return nil;
}


- (void)removeOrder:(NSString *)orderId{
    [self.store removeItemForKey:orderId];
}

- (void)removeALLOrder{
    [self.store removeAllItems];
}

@end
