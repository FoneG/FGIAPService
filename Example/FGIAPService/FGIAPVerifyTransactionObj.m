//
//  FGIAPVerifyTransactionObj.m
//  FGIAPService_Example
//
//  Created by FoneG on 2021/5/10.
//  Copyright © 2021 15757127193@163.com. All rights reserved.
//

#import "FGIAPVerifyTransactionObj.h"

@implementation FGIAPVerifyTransactionObj

- (void)pushSuccessTradeReultToServer:(NSString *)receipt transaction:(SKPaymentTransaction *)transaction complete:(FGIAPVerifyTransactionPushCallBack)handler{
    NSLog(@"%s receipt: %@", __func__ , receipt);
    if (handler) {
//        handler(@"校验订单成功", [NSError errorWithDomain:@"FGIAPVerifyTransactionObj" code:400 userInfo:nil]);
        handler(@"Success", nil);
    }
}

- (void)pushFailTradeReultToServer:(NSString *)tradeNo cancel:(BOOL)userCancelled transaction:(nonnull SKPaymentTransaction *)transaction complete:(nonnull FGIAPVerifyTransactionPushCallBack)handler{
    NSLog(@"%s", __func__);
    if (handler) {
        handler(@"Failure", nil);
    }
}


- (void)pushServiceErrorLogStatistics:(NSDictionary *)logStatistics error:(FGIAPServiceErrorType)error{
    
    NSString *typeString = nil;
    switch (error) {
        case FGIAPServiceErrorTypeTransactionIdentifierNotExist:
            typeString = @"TransactionIdentifier isEmpty";
            break;
        case FGIAPServiceErrorTypeReceiptNotExist:
            typeString = @"Receipt is isEmpty";
            break;
        case FGIAPServiceErrorTypeVerifyTradeFail:
            typeString = @"Verify Receipt failed";
            break;
        default:
            break;
    }
    NSLog(@"%s : %@", __func__, typeString);
    [self showAlert:typeString];
}

- (void)showAlert:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
