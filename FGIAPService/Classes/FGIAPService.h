//
//  FGIAPManager.h
//  MaltBaby
//
//  Created by FoneG on 2020/5/7.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "FGIAPVerifyTransaction.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FGIAPManagerPurchaseRusult) {
    FGIAPManagerPurchaseRusultSuccess = 0,         //内购成功
    FGIAPManagerPurchaseRusultHalfSuccess,         //苹果扣款成功，但是验签接口失败了
    FGIAPManagerPurchaseRusultFail,                //内购失败
    FGIAPManagerPurchaseRusultCancel              //用户取消
};
typedef void(^FGIAPManagerBuyBlock)(NSString *message, FGIAPManagerPurchaseRusult result);

@interface FGIAPService : NSObject

/**
 * 初始化支付对象
 * @param verifyTransaction 一般得到苹果服务器返回的支付结果后，需要通过<verifyTransaction>再次向服务器进行二次确认，来保证整个支付链路闭环
 */
- (instancetype)initWithTransaction:(id<FGIAPVerifyTransaction>)verifyTransaction;

/**
 * iap支付
 * @param product 对应的商品
 * @param completion 支付回调
 */
- (void)buyProduct:(SKProduct *)product onCompletion:(FGIAPManagerBuyBlock)completion;


/**
 * 在合适的时间处理从App Store下载页面触发的内购行为
 */
- (void)tryShouldAddStorePayments;

@end


NS_ASSUME_NONNULL_END
