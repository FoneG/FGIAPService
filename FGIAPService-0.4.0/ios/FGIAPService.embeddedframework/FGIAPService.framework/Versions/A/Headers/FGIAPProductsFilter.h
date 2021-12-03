//
//  FGIAPProductsFilter.h
//  MaltBaby
//
//  Created by FoneG on 2021/5/8.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FGIAPManagerResponseBlock)(NSArray<SKProduct *> * products);

@interface FGIAPProductsFilter : NSObject

/// 获取苹果内购商品列表
/// @param productIdentifiers 商品id列表
/// @param completion completion
- (void)requestProductsWith:(NSSet *)productIdentifiers completion:(nonnull FGIAPManagerResponseBlock)completion;

@end

NS_ASSUME_NONNULL_END
