//
//  FGIAPKeyChainStoreHelper.h
//  MaltBaby
//
//  Created by FoneG on 2020/5/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于处理无法通过transaction获取orderid的情况
@interface FGIAPKeyChainStoreHelper : NSObject

- (void)update:(NSString *)orderId product:(NSString *)productIdentifier;

- (NSString *)requestOneOrderWithProduct:(NSString *)productIdentifier;

- (void)removeOrder:(NSString *)orderId;

- (void)removeALLOrder;

@end

NS_ASSUME_NONNULL_END
