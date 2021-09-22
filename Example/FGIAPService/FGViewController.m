//
//  FGViewController.m
//  FGIAPService
//
//  Created by 15757127193@163.com on 05/08/2021.
//  Copyright (c) 2021 15757127193@163.com. All rights reserved.
//

#import "FGViewController.h"
#import <FGIAPService/FGIAPManager.h>
#import <FGIAPService/FGIAPProductsFilter.h>
#import <Toast.h>

@interface FGViewController ()
@property (nonatomic, strong) FGIAPProductsFilter *filter;
@end

@implementation FGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.filter = [[FGIAPProductsFilter alloc] init];
}
- (IBAction)buy:(id)sender {
    
    NSString *productId = @"替换成申请的productId";
    NSString *tradeNo = @"替换成后台给的tradeNo";
    
    /// 2.获取商品信息
    [self.filter requestProductsWith:[NSSet setWithObject:productId] completion:^(NSArray<SKProduct *> * _Nonnull products) {
        
        /// 3.支付购买
        [[FGIAPManager shared].iap buyProduct:products.firstObject tradeNo:tradeNo onCompletion:^(NSString * _Nonnull message, FGIAPManagerPurchaseRusult result) {
            [self.view makeToast:message];
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
