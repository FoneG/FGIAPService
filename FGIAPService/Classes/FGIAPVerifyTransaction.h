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
    ///找不到匹配的订单号
    FGIAPServiceErrorTypeTradeNoNotExist,
    ///找不到匹配的applicationUsername
    FGIAPServiceErrorTypeApplicationUsernameNoNotExist,
    ///本地存储找不到匹配的orderId
    FGIAPServiceErrorTypeProductStoreNoNotExist,
    ///找不到匹配的票据数据
    FGIAPServiceErrorTypeReceiptNoNotExist,
    ///重新获取，还是找不到匹配的票据数据
    FGIAPServiceErrorTypeReReceiptNoNotExist,
    ///提交验证票据，抛出失败
    FGIAPServiceErrorTypeVerifyTradeFail,
};

typedef void(^FGIAPVerifyTransactionBlock)(NSString *message, FGIAPVerifyTransactionRusult result);
typedef void(^FGIAPVerifyTransactionPushCallBack)(NSString *message,  NSError * _Nullable result);

@protocol FGIAPVerifyTransaction <NSObject>


/// 向服务器校验订单状态
/// @param tradeNo 服务器订单号
/// @param handler 检验回调
- (void)checkTradeReult:(NSString *)tradeNo complete:(nonnull FGIAPVerifyTransactionBlock)handler;

/// 苹果支付流程结束后，需要根据返回的票据等数据去自己的服务器校验
/// @param tradeNo 服务器订单号
/// @param receipt 票据
/// @param transaction 支付事务
/// @param handler 检验回调
- (void)pushSuccessTradeReultToServer:(NSString *)tradeNo receipt:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction complete:(FGIAPVerifyTransactionPushCallBack)handler;


/// 支付流程取消后，需要将返回的订单信息告知服务器
/// @param tradeNo 服务器订单号
/// @param userCancelled 是否用户主动取消
/// @param transaction 支付事务
/// @param handler 检验回调
- (void)pushFailTradeReultToServer:(NSString *)tradeNo cancel:(BOOL)userCancelled transaction:(SKPaymentTransaction *)transaction complete:(FGIAPVerifyTransactionPushCallBack)handler;

@optional
/// 推送失败日志
/// @param logStatistics 日志
- (void)pushServiceErrorLogStatistics:(NSDictionary *)logStatistics error:(FGIAPServiceErrorType)error;

@end

NS_ASSUME_NONNULL_END
