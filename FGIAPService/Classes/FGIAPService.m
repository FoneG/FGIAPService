//
//  FGIAPManager.m
//  MaltBaby
//
//  Created by FoneG on 2020/5/7.
//

#import "FGIAPService.h"
#import "FGIAPServiceUtility.h"
#import "NSObject+FGIsNullOrEmpty.h"

static NSMutableDictionary *FGIAPServiceErrorMapsFromTransaction (SKPaymentTransaction *transaction) {
    NSMutableDictionary *errorMaps = [NSMutableDictionary dictionary];
    [errorMaps setValue:transaction.transactionIdentifier?:@"" forKey:@"transactionIdentifier"];
    [errorMaps setValue:transaction.originalTransaction.transactionIdentifier?:@"" forKey:@"originalTransaction.transactionIdentifier"];
    [errorMaps setValue:transaction.payment.applicationUsername?:@"" forKey:@"applicationUsername"];
    [errorMaps setValue:transaction.payment.productIdentifier?:@"" forKey:@"productIdentifier"];
    return errorMaps;
}

@interface FGIAPService () <SKPaymentTransactionObserver, SKRequestDelegate>
@property (nonatomic, strong) id<FGIAPVerifyTransaction> verifyTransaction;
@property (nonatomic, copy) FGIAPManagerBuyBlock buyProductCompleteBlock;
@property (nonatomic, strong) NSString *productIdentifier;

@end

@implementation FGIAPService

- (instancetype)initWithTransaction:(id<FGIAPVerifyTransaction>)verifyTransaction{
    if (self = [super init]) {
        
        _verifyTransaction = verifyTransaction;
                
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        }
    }
    return self;
}


- (void)buyProduct:(SKProduct *)product onCompletion:(nonnull FGIAPManagerBuyBlock)completion{

    if (![SKPaymentQueue canMakePayments]) {
        completion(@"Failed to obtain the internal purchase permission", FGIAPManagerPurchaseRusultFail);
        return;
    }
    if ([product.productIdentifier isNSStringAndNotEmpty]) {
        self.productIdentifier = product.productIdentifier;
        self.buyProductCompleteBlock = completion;
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }else{
        completion(@"The selected payment does not exist", FGIAPManagerPurchaseRusultFail);
    }
}


#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    FGLog(@"%s %ld", __func__, [SKPaymentQueue defaultQueue].transactions.count);
    if (![[SKPaymentQueue defaultQueue].transactions isNSArrayAndNotEmpty]) {
        /// all transactions finished
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                FGLog(@"Add an payment to the list");
                break;
            case SKPaymentTransactionStatePurchased:
                FGLog(@"Customer paid successfully");
                [self completeTransaction:transaction retryWhenreceiptURLisEmpty:YES];
                break;
            case SKPaymentTransactionStateRestored:
                FGLog(@"The transaction has been recovered from the user's purchase history");
                [self completeTransaction:transaction retryWhenreceiptURLisEmpty:YES];
                break;
            case SKPaymentTransactionStateFailed:
                FGLog(@"Failure of commodity transaction");
                [self failedTransaction:transaction withError:FGIAPServiceErrorTypeNone];
                break;
            case SKPaymentTransactionStateDeferred:
                FGLog(@"Merchandise is suspended");
                break;
            default:
                ///
                break;
        }
    }
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product NS_SWIFT_NAME(paymentQueue(_:shouldAddStorePayment:for:)) API_AVAILABLE(ios(11.0), macos(11.0), macCatalyst(14.0)) API_UNAVAILABLE(watchos){
    return false;
}


#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        SKReceiptRefreshRequest *RefreshRequest = (SKReceiptRefreshRequest *)request;
        SKPaymentTransaction *transaction = [RefreshRequest.receiptProperties valueForKey:@"transaction"];
        if (transaction) {
            [self completeTransaction:transaction retryWhenreceiptURLisEmpty:NO];
        }else{
            [self failedTransaction:transaction withError:FGIAPServiceErrorTypeReceiptNotExist];
        }
    }
}

- (void)request:(SKRequest *)request didFailWithError:(nonnull NSError *)error{
    if ([request isKindOfClass:[SKReceiptRefreshRequest class]]) {
        SKReceiptRefreshRequest *RefreshRequest = (SKReceiptRefreshRequest *)request;
        SKPaymentTransaction *transaction = [RefreshRequest.receiptProperties valueForKey:@"transaction"];
        [self failedTransaction:transaction withError:FGIAPServiceErrorTypeReceiptNotExist];
    }
}


#pragma mark - private method

- (void)completeTransaction:(SKPaymentTransaction *)transaction retryWhenreceiptURLisEmpty:(BOOL)retry{
    FGLog(@"%s %@ %@", __func__, transaction.transactionIdentifier, transaction.originalTransaction.transactionIdentifier);
            
    if (![transaction.transactionIdentifier isNSStringAndNotEmpty]) {
        [self failedTransaction:transaction withError:FGIAPServiceErrorTypeTransactionIdentifierNotExist];
        return;
    }
    
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:receiptURL.path]) {
        
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        NSString *receiptDataText = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        [self checkReceipt:receiptDataText withTransaction:transaction handler:nil];
        
    }else if (retry){
        
        SKReceiptRefreshRequest *receiptRefreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{@"transaction":transaction}];
        receiptRefreshRequest.delegate = self;
        [receiptRefreshRequest start];
        
    }else{
        [self failedTransaction:transaction withError:FGIAPServiceErrorTypeReceiptNotExist];
    }
}


- (void)failedTransaction:(SKPaymentTransaction *)transaction withError:(FGIAPServiceErrorType)error{
    FGLog(@"%s Transaction error:%@ code:%ld", __func__, transaction.error.localizedDescription, transaction.error.code);
    
    BOOL finish = error == FGIAPServiceErrorTypeNone;
    
    if (finish && [SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    
    NSMutableDictionary *logStatistics = [NSMutableDictionary dictionaryWithDictionary:FGIAPServiceErrorMapsFromTransaction(transaction)];
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushServiceErrorLogStatistics:error:)]) {
        [self.verifyTransaction pushServiceErrorLogStatistics:logStatistics error:error];
    }
    
    if (_buyProductCompleteBlock) {
        FGIAPManagerPurchaseRusult result = FGIAPManagerPurchaseRusultHalfSuccess;
        if (error == FGIAPServiceErrorTypeNone) {
            result = transaction.error.code == SKErrorPaymentCancelled ? FGIAPManagerPurchaseRusultCancel : FGIAPManagerPurchaseRusultFail;
        }
        _buyProductCompleteBlock(transaction.error.localizedDescription, result);
    }
}



- (void)checkReceipt:(NSString *)receipt withTransaction:(SKPaymentTransaction *)transaction handler:(FGIAPVerifyTransactionBlock)handler{
    
    WS(wSelf);
    if (self.verifyTransaction && [self.verifyTransaction respondsToSelector:@selector(pushSuccessTradeReultToServer:transaction:complete:)]) {
        [self.verifyTransaction pushSuccessTradeReultToServer:receipt transaction:transaction complete:^(NSString * _Nonnull message, NSError * _Nullable requestErr) {

            //polling verify transaction
            if (requestErr && requestErr.code != FGIAPServerOverdueErrorCode) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [wSelf checkReceipt:receipt withTransaction:transaction handler:handler];
                });
                return;
            }
            
            [wSelf finishTransaction:transaction result: FGIAPManagerPurchaseRusultSuccess message:message];
        }];
    }else{
        NSAssert(NO, @"You must configure the method: - pushSuccessTradeReultToServer:transaction:complete:");
    }
}


- (void)finishTransaction:(SKPaymentTransaction *)transaction result:(FGIAPManagerPurchaseRusult)result message:(NSString *)msg{
    
    FGLog(@"%s finishTransaction:%@", __func__, transaction.transactionIdentifier);
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
    
    if (transaction.originalTransaction == nil && [transaction.payment.productIdentifier isEqualToString:self.productIdentifier]) {
        self.productIdentifier = nil;
        if (self.buyProductCompleteBlock) {
            self.buyProductCompleteBlock(msg, result);
        }
    }
}

@end
