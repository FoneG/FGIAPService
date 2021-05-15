# FGIAPService

FGIAPService 是一套用于解决苹果IAP的解决方案，适用于希望自己架设服务器进行验证的开发者


# Cocoapod
```
pod 'FGIAPService'
```

# Initialize

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    ···
    [[FGIAPManager shared] setConfigureWith: id<FGIAPVerifyTransaction>];

    ···
}

```

# Request Products

```
        [[[FGIAPProductsFilter alloc] init] requestProductsWith:[[NSSet alloc] initWithArray:@[product.productId]] completion:^(NSArray<SKProduct *> * _Nonnull products) {
        }];
```


# Purchase

```
      [[FGIAPManager shared].FGIAPService buyProduct:product tradeNo:tradeNo onCompletion:^(NSString * _Nonnull message, FGIAPManagerPurchaseRusult result) {
        
      }];
```
