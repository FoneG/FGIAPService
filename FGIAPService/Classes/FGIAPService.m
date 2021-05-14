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
#import "NSArray+FGIsNullOrEmpty.h"

@interface FGIAPService () <SKPaymentTransactionObserver, SKRequestDelegate>

@property (nonatomic, strong) id<FGIAPVerifyTransaction> verifyTransaction;

@property (nonatomic, copy) FGIAPManagerBuyBlock buyProductCompleteBlock;

@property (nonatomic, strong) NSString *handleTradeNo;
/// 保存内购成功但校验失败未finish的Transaction，用于重新获取票据，以及轮询重试
@property (nonatomic, strong) NSMutableDictionary <NSString *,FGIAPTransaction *>*transactionMaps;

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
        /// 购买
        self.buyProductCompleteBlock = completion;
        
        /// 用于applicationUsername、transactionIdentifier为空情况的处理
        [self.productStore update:tradeNo product:product.productIdentifier];
        
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        // 有一些特殊情况会导致payment.applicationUsername 为空. 所以自己额外存储tradeNo
        payment.applicationUsername = tradeNo;
        
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }else{
        completion(@"选中的商品id不存在", FGIAPManagerPurchaseRusultFail);
    }
}

- (void)verifyServerTradeReult:(NSString *)tradeNo complete:(nonnull FGIAPVerifyTransactionBlock)handler{
    
    __block BOOL exist = NO;
    [self.transactionMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FGIAPTransaction * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!obj.handle) exist = YES;
    }];
    if (exist) {
        [self _verifyTrade:tradeNo handler:handler];
    }else if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(checkTradeReult:complete:)]) {
        [self.verifyTransaction checkTradeReult:tradeNo complete:^(NSString * _Nonnull message, FGIAPVerifyTransactionRusult result) {
            if (handler) {
                handler(message, result);
            }
        }];
    }else{
        if (handler) {
            handler(@"verifyTransaction不存在", FGIAPManagerVerifyRusultFail);
        }
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
    
    /// 服务器订单ID
    NSString *tradeNo  = [self _tradeNoOfTransaction:transaction];
    
    NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
    [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
    [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
    [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];
    [errorMaps setValue:retry?@"1":@"0" forKey:@"retry"];
    [errorMaps setValue:tradeNo?:@"" forKey:@"tradeNo"];

    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        [self _showAlert:@"无法获取订单号，如果存在支付异常，请尝试重启APP或者联系客服"];
    }else{
        /// 用于漏单轮询重试
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
            FGLog(@"@@## 重新请求票据信息");
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:errorMaps];
        }else{
            /// 放到重试定时器中
            m_transction.handle = NO;
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReReceiptNoNotExist parms:errorMaps];
            [self _showAlert:@"无法获取票据，如果存在支付异常，请尝试重启APP或者联系客服"];
        }
    }
}

- (void)_showAlert:(NSString *)message{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:action];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
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
                    NSMutableDictionary *paras = [NSMutableDictionary dictionary];
                    [paras setValue:tradeNo forKey:@"tradeNo"];
                    [paras setValue:cancel?@"CANCEL":@"FAIL" forKey:@"payResult"];
                    [paras setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
                    
                    NSMutableDictionary *ErrorMaps = [NSMutableDictionary dictionaryWithDictionary:paras];
                    [ErrorMaps setValue:requestErr.description?:@"" forKey:@"requestErr"];
                    [ErrorMaps setValue:@(requestErr.code) forKey:@"requestErrCode"];
                    [wSelf p_uploadErrorMaps:FGIAPServiceErrorTypeVerifyTradeFail parms:ErrorMaps];
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
            NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
            [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
            [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
            [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];
            [errorMaps setValue:@"重新请求票据信息 成功 但定位不到对应的事务" forKey:@"event"];
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:errorMaps];
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(nonnull NSError *)error{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        SKReceiptRefreshRequest *RefreshRequest = (SKReceiptRefreshRequest *)request;
        SKPaymentTransaction *transaction = [RefreshRequest.receiptProperties valueForKey:@"transaction"];
        
        NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
        [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
        [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
        [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];
        [errorMaps setValue:@"重新请求票据信息 失败" forKey:@"event"];
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeReceiptNoNotExist parms:errorMaps];
    }
}


#pragma mark - private method

- (NSString *)_tradeNoOfTransaction:(SKPaymentTransaction *)transaction{
    __block NSString *tradeNo = nil;
    
    NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
    [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
    [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
    [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];

    /// 主要是要保证 orderId和对应的 receiptData能够上传给服务器做校验
    if ([transaction.payment.applicationUsername FG_isNSStringAndNotEmpty]) {
        tradeNo = transaction.payment.applicationUsername;
        FGLog(@"@@## 读取applicationUsername中的orderID");
    }else{
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeApplicationUsernameNoNotExist parms:errorMaps];
    }

    /// 如果漏单在重新校验的过程中tradeNo丢失，尝试读取maps中的缓存
    /// fix:这个步骤，可以来解决 FGIAPProductKeyChainStore 每次获取到的tradeNo不同的问题
    if (![tradeNo FG_isNSStringAndNotEmpty]){
        
        if ([transaction.transactionIdentifier FG_isNSStringAndNotEmpty]) {
            [self.transactionMaps enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, FGIAPTransaction * _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj.transaction.transactionIdentifier isEqualToString:transaction.transactionIdentifier]) {
                    tradeNo = key;
                    *stop = YES;
                    FGLog(@"@@## 读取transactionMaps中的缓存orderID");
                }
            }];
        }else{
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeTransactionIdNoNotExist parms:errorMaps];
        }
    }
    
    /// 无法根据transaction获取订单，只要productIdentifier一致就直接取出来使用
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        NSString *storeTradeNo = [self.productStore requestOneOrderWithProduct:transaction.payment.productIdentifier];
        if ([storeTradeNo FG_isNSStringAndNotEmpty]) {
            tradeNo = storeTradeNo;
            FGLog(@"@@## 读取ProductKeyChainStore中的缓存orderID");
        }else{
            [self p_uploadErrorMaps:FGIAPServiceErrorTypeProductStoreNoNotExist parms:errorMaps];
        }
    }
    if (![tradeNo FG_isNSStringAndNotEmpty]) {
        [self p_uploadErrorMaps:FGIAPServiceErrorTypeTradeNoNotExist parms:errorMaps];
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
    
    /// 苹果扣款成功，但是验签接口失败了 不能直接结束，需要重新校验
    if (result != FGIAPManagerPurchaseRusultHalfSuccess) {
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        if ([tradeNo FG_isNSStringAndNotEmpty]) {
            /// 校验成功后移除
            [self.transactionMaps removeObjectForKey:tradeNo];
            /// 校验成功后移除
            [self.productStore removeOrder:tradeNo];
        }
    }
    
    BOOL exist = [tradeNo isEqualToString:self.handleTradeNo];
    if (exist) {
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
            handler(@"orderId不存在", FGIAPManagerVerifyRusultFail);
        }
        return;
    }
    
    WS(wSelf);
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushSuccessTradeReultToServer:receipt:transaction:complete:)]) {
        [self.verifyTransaction pushSuccessTradeReultToServer:tradeNo receipt:receipt transaction:iap.transaction complete:^(NSString * _Nonnull message, NSError * _Nullable requestErr) {
            /// 订单提交无效，需要删除本地的订单
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

- (void)p_uploadErrorMaps:(FGIAPServiceErrorType)error parms:(NSDictionary *)parms{
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushServiceErrorLogStatistics:error:)]) {
        [self.verifyTransaction pushServiceErrorLogStatistics:parms error:error];
    }
}

@end
