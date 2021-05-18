//
//  FGIAPManager.m
//  MaltBaby
//
//  Created by FoneG on 2020/5/7.
//

#import "FGIAPService.h"
#import "FGIAPKeyChainStoreHelper.h"
#import "FGIAPTransaction.h"
#import "FGIAPServiceUtility.h"
#import "NSObject+FGIsNullOrEmpty.h"


static NSMutableDictionary *FGIAPServiceErrorMapsFromTransaction (SKPaymentTransaction *transaction) {
    NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
    [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
    [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
    [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];
    return errorMaps;
}

@interface FGIAPService () <SKPaymentTransactionObserver, SKRequestDelegate>
/// 保存内购成功但校验失败未finish的Transaction，用于重新获取票据，以及轮询重试
@property (nonatomic, strong) NSMutableDictionary <NSString *,FGIAPTransaction *>*transactionMaps;
@property (nonatomic, strong) id<FGIAPVerifyTransaction> verifyTransaction;
@property (nonatomic, copy) FGIAPManagerBuyBlock buyProductCompleteBlock;
@property (nonatomic, strong) NSString *handleTradeNo;
@property (nonatomic, strong) FGIAPKeyChainStoreHelper *productStore;
@property (nonatomic, strong) NSTimer *repeatTimer;

@end

@implementation FGIAPService

- (instancetype)initWithTransaction:(id<FGIAPVerifyTransaction>)verifyTransaction{
    if (self = [super init]) {
        _verifyTransaction = verifyTransaction;

        _transactionMaps = [NSMutableDictionary dictionary];
        _productStore = [[FGIAPKeyChainStoreHelper alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
        NSTimeInterval FGIAPServiceTradeVerifyInterval = 10.0f;
        _repeatTimer = [NSTimer timerWithTimeInterval:FGIAPServiceTradeVerifyInterval target:self selector:@selector(_reVerify) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_repeatTimer forMode:NSRunLoopCommonModes];
        [_repeatTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:FGIAPServiceTradeVerifyInterval]];
    }
    return self;
}


- (void)buyProduct:(SKProduct *)product tradeNo:(nonnull NSString *)tradeNo onCompletion:(nonnull FGIAPManagerBuyBlock)completion{

    if (![SKPaymentQueue canMakePayments]) {
        completion(@"@@## 获取内购权限失败", FGIAPManagerPurchaseRusultFail);
        return;
    }
    if ([product.productIdentifier FG_isNSStringAndNotEmpty] && [tradeNo FG_isNSStringAndNotEmpty]) {
        self.handleTradeNo = tradeNo;
        self.buyProductCompleteBlock = completion;
        /// 用于applicationUsername、transactionIdentifier为空情况的处理
        [self.productStore update:tradeNo product:product.productIdentifier];
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.applicationUsername = tradeNo;
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }else{
        completion(@"选中的商品id不存在", FGIAPManagerPurchaseRusultFail);
    }
}

- (void)clear{
    [self.repeatTimer invalidate];
    self.repeatTimer = nil;
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    FGLog(@"@@## %s %ld", __func__, [SKPaymentQueue defaultQueue].transactions.count);
    if (![[SKPaymentQueue defaultQueue].transactions FG_isNSArrayAndNotEmpty]) {
        [self.productStore removeALLOrder];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                FGLog(@"@@## 商品添加进列表");
                break;
            case SKPaymentTransactionStatePurchased:
                FGLog(@"@@## 客户完成交易");
                [self completeTransaction:transaction retryWhenreceiptURLisEmpty:YES];
                break;
            case SKPaymentTransactionStateRestored:
                FGLog(@"@@## 事务已从用户的购买历史中恢复。客户应完成交易。");
                [self completeTransaction:transaction retryWhenreceiptURLisEmpty:YES];
                break;
            case SKPaymentTransactionStateFailed:
                FGLog(@"@@## 商品交易失败");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateDeferred:
                FGLog(@"@@## 商品被挂起");
                break;
            default:
                ///
                break;
        }
    }
}


- (void)completeTransaction:(SKPaymentTransaction *)transaction retryWhenreceiptURLisEmpty:(BOOL)retry{
    FGLog(@"@@## %s %@ %@", __func__, transaction.transactionIdentifier, transaction.payment.applicationUsername);
        
    NSString *tradeNo  = [self _tradeNoOfTransaction:transaction];
    
    NSMutableDictionary *errorMaps = FGIAPServiceErrorMapsFromTransaction(transaction);
    [errorMaps setValue:tradeNo?:@"" forKey:@"tradeNo"];

    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        [self _showAlert:@"无法获取订单号，如果存在支付异常，请尝试重启APP或者联系客服"];
        [self _finishTransaction:transaction result:FGIAPManagerPurchaseRusultHalfSuccess message:@"无法获取订单号"];
    }else{
        /// fix：用于漏单轮询重试
        FGIAPTransaction *m_transction = [[FGIAPTransaction alloc] init];
        m_transction.transaction = transaction;
        m_transction.handle = YES;
        [self.transactionMaps setValue:m_transction forKey:tradeNo];

        // 从沙盒中获取到购买凭据
        // 取receipt的时候要判空，如果文件不存在，就要从苹果服务器重新刷新下载receipt了。
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        if ([[NSFileManager defaultManager] fileExistsAtPath:receiptURL.path]) {
            
            NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
            NSString *receiptDataText = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            m_transction.receipt = receiptDataText;
            [self _verifyTrade:tradeNo handler:nil];
        }else if (retry){
            SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{@"transaction":transaction}];
            receiptRefreshRequest.delegate = self;
            [receiptRefreshRequest start];
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:errorMaps];
        }else{
            m_transction.handle = NO;
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReReceiptNoNotExist parms:errorMaps];
            [self _showAlert:@"无法获取票据，如果存在支付异常，请尝试重启APP或者联系客服"];
            [self _finishTransaction:transaction result:FGIAPManagerPurchaseRusultHalfSuccess message:@"无法获取票据"];
        }
    }
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    FGLog(@"@@## %s %@ %@", __func__, transaction.transactionIdentifier, transaction.payment.applicationUsername);

    NSString *tradeNo  = [self _tradeNoOfTransaction:transaction];

    NSInteger cancel = transaction.error.code == SKErrorPaymentCancelled;
    FGIAPManagerPurchaseRusult result = cancel ? FGIAPManagerPurchaseRusultCancel : FGIAPManagerPurchaseRusultFail;
    NSString *message = cancel ? @"用户取消" : @"购买失败";
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        [self _finishTransaction:transaction result:result message:message];
    }else{
        WS(wSelf);
        if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushFailTradeReultToServer:cancel:transaction:complete:)]) {
            
            [self.verifyTransaction pushFailTradeReultToServer:tradeNo cancel:cancel transaction:transaction complete:^(NSString * _Nonnull requestMessage, NSError * _Nullable requestErr) {
                if (!requestErr) {
                    [wSelf _finishTransaction:transaction result:result message:message];
                }else{
                    if (requestErr.code == FGIAPServerOverdueErrorCode) {
                        [wSelf.productStore removeOrder:tradeNo];
                    }
                    BOOL exist = [tradeNo isEqualToString:self.handleTradeNo];
                    if (exist) {
                        wSelf.handleTradeNo = nil;
                        if (wSelf.buyProductCompleteBlock) {
                            wSelf.buyProductCompleteBlock(requestErr.description, result);
                        }
                    }
                    NSMutableDictionary *paras = FGIAPServiceErrorMapsFromTransaction(transaction);
                    [paras setValue:tradeNo forKey:@"tradeNo"];
                    [paras setValue:cancel?@"CANCEL":@"FAIL" forKey:@"payResult"];
                    [wSelf p_uploadErrorMaps:FGIAPServiceErrorTypeVerifyTradeFail parms:paras];
                }
            }];
        }
    }
}


#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        SKReceiptRefreshRequest *RefreshRequest = (SKReceiptRefreshRequest *)request;
        SKPaymentTransaction *transaction = [RefreshRequest.receiptProperties valueForKey:@"transaction"];
        if (transaction) {
            [self completeTransaction:transaction retryWhenreceiptURLisEmpty:NO];
        }else{
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:FGIAPServiceErrorMapsFromTransaction(transaction)];
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(nonnull NSError *)error{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        SKReceiptRefreshRequest *RefreshRequest = (SKReceiptRefreshRequest *)request;
        SKPaymentTransaction *transaction = [RefreshRequest.receiptProperties valueForKey:@"transaction"];
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:FGIAPServiceErrorMapsFromTransaction(transaction)];
    }
}


#pragma mark - private method

- (NSString *)_tradeNoOfTransaction:(SKPaymentTransaction *)transaction{
    __block NSString *tradeNo = nil;
    if ([transaction.payment.applicationUsername FG_isNSStringAndNotEmpty]) {
        tradeNo = transaction.payment.applicationUsername;
    }else{
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeApplicationUsernameNoNotExist parms:FGIAPServiceErrorMapsFromTransaction(transaction)];
    }
    
    /// 无法根据transaction获取订单，只要productIdentifier一致就直接取出来使用
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        NSString *storeTradeNo = [self.productStore requestOneOrderWithProduct:transaction.payment.productIdentifier];
        if ([storeTradeNo FG_isNSStringAndNotEmpty]) {
            tradeNo = storeTradeNo;
        }else{
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeProductStoreNoNotExist parms:FGIAPServiceErrorMapsFromTransaction(transaction)];
        }
    }
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeTradeNoNotExist parms:FGIAPServiceErrorMapsFromTransaction(transaction)];
    }
    return tradeNo;
}

- (void)_finishTransaction:(SKPaymentTransaction *)transaction result:(FGIAPManagerPurchaseRusult)result message:(NSString *)msg{

    NSString *tradeNo  = [self _tradeNoOfTransaction:transaction];
    FGIAPTransaction *iap = nil;
    if ([tradeNo FG_isNSStringAndNotEmpty]) {
        iap = [self.transactionMaps valueForKey:tradeNo];
        iap.handle = NO;
    }
    
    if (result == FGIAPManagerPurchaseRusultHalfSuccess) {
        /// 苹果扣款成功，但是验签接口失败了  不能直接finishTransaction，需要重新校验
    }else{
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        if ([tradeNo FG_isNSStringAndNotEmpty]) {
            /// 校验成功后移除
            [self.transactionMaps removeObjectForKey:tradeNo];
            [self.productStore removeOrder:tradeNo];
        }
    }
    
    BOOL finish = ![tradeNo FG_isNSStringAndNotEmpty] || [tradeNo isEqualToString:self.handleTradeNo];
    if (finish) {
        self.handleTradeNo = nil;
        if (self.buyProductCompleteBlock) {
            self.buyProductCompleteBlock(msg, result);
        }
    }
}


- (void)_verifyTrade:(NSString *)tradeNo handler:(FGIAPVerifyTransactionBlock)handler{
    
    FGIAPTransaction *iap = [self.transactionMaps valueForKey:tradeNo];
    iap.handle = YES;
    NSString *receipt = iap.receipt;
    if (![receipt FG_isNSStringAndNotEmpty]) {
        if (handler) {
            handler(@"receipt不存在", FGIAPManagerVerifyRusultFail);
        }
        return;
    }
    
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        if (handler) {
            handler(@"tradeNo不存在", FGIAPManagerVerifyRusultFail);
        }
        return;
    }
    
    WS(wSelf);
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushSuccessTradeReultToServer:receipt:transaction:complete:)]) {
        [self.verifyTransaction pushSuccessTradeReultToServer:tradeNo receipt:receipt transaction:iap.transaction complete:^(NSString * _Nonnull message, NSError * _Nullable requestErr) {
            if (requestErr.code == FGIAPServerOverdueErrorCode) {
                [wSelf.productStore removeOrder:tradeNo];
            }
            [wSelf _finishTransaction:iap.transaction result: requestErr ? FGIAPManagerPurchaseRusultHalfSuccess : FGIAPManagerPurchaseRusultSuccess message:message];
        }];
    }else{
        if (handler) {
            handler(@"校验失败",FGIAPManagerVerifyRusultFail);
        }
    }
}

- (void)_reVerify{
    [self.transactionMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FGIAPTransaction * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!obj.handle) {
            [self _verifyTrade:key handler:nil];
        }
    }];
}

- (void)_showAlert:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(touchNeedManuallyResolvedEvent:)]) {
            [self.verifyTransaction touchNeedManuallyResolvedEvent:message];
        }
    }];
    [alertController addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
}


- (void)p_uploadErrorMaps:(FGIAPServiceErrorType)error parms:(NSDictionary *)parms{
    NSString *typeString = nil;
    switch (error) {
        case FGIAPServiceErrorTypeTradeNoNotExist:
            typeString = @"找不到匹配的订单号";
            break;
        case FGIAPServiceErrorTypeApplicationUsernameNoNotExist:
            typeString = @"找不到匹配的applicationUsername";
            break;
        case FGIAPServiceErrorTypeProductStoreNoNotExist:
            typeString = @"本地存储找不到匹配的orderId";
            break;
        case FGIAPServiceErrorTypeReceiptNoNotExist:
            typeString = @"找不到匹配的票据数据";
            break;
        case FGIAPServiceErrorTypeReReceiptNoNotExist:
            typeString = @"重新获取，还是找不到匹配的票据数据";
            break;
        case FGIAPServiceErrorTypeVerifyTradeFail:
            typeString = @"提交验证票据，抛出失败";
            break;
        default:
            typeString = @"未知";
            break;
    }
    NSMutableDictionary *logStatistics = [NSMutableDictionary dictionaryWithDictionary:parms];
    [logStatistics setValue:typeString forKey:@"typeString"];
    FGLog(@"@@## p_uploadErrorMaps: %@", logStatistics);
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushServiceErrorLogStatistics:error:)]) {
        [self.verifyTransaction pushServiceErrorLogStatistics:logStatistics error:error];
    }
}

@end
