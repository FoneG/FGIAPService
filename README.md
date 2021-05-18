# 说明

FGIAPService 是一套用于解决苹果IAP的解决方案，适用于希望自己架设服务器进行验证的开发者, 能够非常简单快速地接入到项目中

[更详细的介绍](https://note.youdao.com/ynoteshare1/index.html?id=47a9aacd3372867c15b8a3d4ff37d75d&type=note)

# Cocoapod
```
pod 'FGIAPService'
```

# FGIAPService 解决的问题
* 窜单（订单映射）
* 漏单
* 账号切换
* apple验证
* 票据异常
* 数据丢失
* ...

# 使用

配置服务器校验代理对象
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    ···
    [[FGIAPManager shared] setConfigureWith: id<FGIAPVerifyTransaction>];

    ···
}

```

通过productId获取苹果商品列表
```
[[[FGIAPProductsFilter alloc] init] requestProductsWith:[[NSSet alloc] initWithArray:@[product.productId]] completion:^(NSArray<SKProduct *> * _Nonnull products) {
    ///
}];
```


通过商品信息和对应的tradeNo进行支付
```
[[FGIAPManager shared].FGIAPService buyProduct:product tradeNo:tradeNo onCompletion:^(NSString * _Nonnull message, FGIAPManagerPurchaseRusult result) {
    ///        
}];
```


# 问题交流
如果大家发现bug，请在GitHub提issue    
好用的话，请路过的朋友们给点个star 🙏🙏🙏🙏🙏
