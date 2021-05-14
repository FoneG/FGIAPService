//
//  FGIAPProductsFilter.m
//  MaltBaby
//
//  Created by FoneG on 2021/5/8.
//

#import "FGIAPProductsFilter.h"
#import "FGIAPServiceUtility.h"

@interface FGIAPProductsFilter ()<SKProductsRequestDelegate>
@property (nonatomic,strong) SKProductsRequest *request;
@property (nonatomic, copy) FGIAPManagerResponseBlock requestProductsBlock;
@end

@implementation FGIAPProductsFilter

- (void)requestProductsWith:(NSSet *)productIdentifiers completion:(nonnull FGIAPManagerResponseBlock)completion{
    
    if (productIdentifiers.count==0) {
        if (completion) completion([NSArray array]);
        return;
    }
    self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
    self.request.delegate = self;
    self.requestProductsBlock = completion;
    [self.request start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = [response.products sortedArrayUsingComparator:^NSComparisonResult(SKProduct *obj1, SKProduct *obj2) {
        return obj1.price.doubleValue < obj2.price.doubleValue ? NSOrderedAscending : NSOrderedDescending;
    }];
    if(_requestProductsBlock) {
        _requestProductsBlock(products);
    }
}

@end
