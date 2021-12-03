//
//  FGIAPVerifyTransaction.h
//  MaltBaby
//
//  Created by FoneG on 2021/5/8.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FGIAPVerifyTransactionRusult) {
    FGIAPManagerVerifyRusultCREATED = 0,
    FGIAPManagerVerifyRusultFail,
    FGIAPManagerVerifyRusultSuccess,
};

typedef NS_ENUM(NSInteger, FGIAPServiceErrorType) {
    FGIAPServiceErrorTypeNone,
    ///Failed to validate receipt
    FGIAPServiceErrorTypeTransactionIdentifierNotExist,
    ///No matching receipt data was found
    FGIAPServiceErrorTypeReceiptNotExist,
    ///Failed to validate receipt
    FGIAPServiceErrorTypeVerifyTradeFail,
};

typedef void(^FGIAPVerifyTransactionBlock)(NSString *message, FGIAPVerifyTransactionRusult result);
typedef void(^FGIAPVerifyTransactionPushCallBack)(NSString *message,  NSError * _Nullable result);

@protocol FGIAPVerifyTransaction <NSObject>

/// 苹果支付流程结束后，需要根据返回的票据等数据去自己的服务器校验
/// @param receipt 票据
/// @param transaction 支付事务
/// @param handler 检验回调
- (void)pushSuccessTradeReultToServer:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction complete:(FGIAPVerifyTransactionPushCallBack)handler;


@optional

/// 推送失败日志
/// @param logStatistics 日志
- (void)pushServiceErrorLogStatistics:(NSDictionary *)logStatistics error:(FGIAPServiceErrorType)error;

/**
Promoting In-App Purchases
 
 用户如果在 App下载页面点击购买你推广的内购商品，如果用户已经安装过你的 App 则会直接跳转你的App并调用上述代理方法；如果用户还没有安装你的 App 那么就会去下载你的 App，下载完成之后系统会推送一个通知，如果用户点击该通知就会跳转到你的App并且调用上面的代理方法

 上面的代理方法返回 true 则表示跳转到你的 App，IAP 继续完成交易，如果返回 false 则表示推迟或者取消购买，实际开发中因为可能还需要用户登录自己的账号、生成订单等，一般都是返回 false，之后通过
 */
- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product API_AVAILABLE(ios(11.0));

@end

NS_ASSUME_NONNULL_END
