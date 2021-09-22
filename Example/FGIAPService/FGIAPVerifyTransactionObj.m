//
//  FGIAPVerifyTransactionObj.m
//  FGIAPService_Example
//
//  Created by FoneG on 2021/5/10.
//  Copyright © 2021 15757127193@163.com. All rights reserved.
//

#import "FGIAPVerifyTransactionObj.h"

@implementation FGIAPVerifyTransactionObj

- (void)pushSuccessTradeReultToServer:(NSString *)tradeNo receipt:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction complete:(nonnull FGIAPVerifyTransactionPushCallBack)handler{
    NSLog(@"将内购成功结果推给服务器");
    if (handler) {
        handler(@"校验订单成功", nil);
    }
}

- (void)pushFailTradeReultToServer:(NSString *)tradeNo cancel:(BOOL)userCancelled transaction:(nonnull SKPaymentTransaction *)transaction complete:(nonnull FGIAPVerifyTransactionPushCallBack)handler{
    NSLog(@"将内购失败结果推给服务器");
    if (handler) {
        handler(@"校验成功", nil);
    }
}

- (void)checkTradeReult:(NSString *)tradeNo complete:(nonnull FGIAPVerifyTransactionBlock)handler{
    NSLog(@"去服务器检查");
    if (handler) {
        handler(@"校验成功", FGIAPManagerVerifyRusultSuccess);
    }
}

- (void)pushServiceErrorLogStatistics:(NSDictionary *)logStatistics error:(FGIAPServiceErrorType)error{
    NSLog(@"将错误日志结果推给服务器");
}

@end
