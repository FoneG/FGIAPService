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
        handler(@"Success", nil);
    }
}

- (void)pushServiceErrorLogStatistics:(NSDictionary *)logStatistics error:(FGIAPServiceErrorType)error{
    
    switch (error) {
        case FGIAPServiceErrorTypeTransactionIdentifierNotExist:
            [self showAlert:@"TransactionIdentifier isEmpty"];
            break;
        case FGIAPServiceErrorTypeReceiptNotExist:
            [self showAlert:@"Receipt is isEmpty"];
            break;
        case FGIAPServiceErrorTypeVerifyTradeFail:
            [self showAlert:@"Verify Receipt failed"];
            break;
        default:
            break;
    }
}

- (void)showAlert:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}

@end
