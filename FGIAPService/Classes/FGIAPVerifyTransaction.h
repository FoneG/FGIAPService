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

@end

NS_ASSUME_NONNULL_END
