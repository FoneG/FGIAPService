# FGIAPService

[![CI Status](https://img.shields.io/travis/15757127193@163.com/FGIAPService.svg?style=flat)](https://travis-ci.org/15757127193@163.com/FGIAPService)
[![Version](https://img.shields.io/cocoapods/v/FGIAPService.svg?style=flat)](https://cocoapods.org/pods/FGIAPService)
[![License](https://img.shields.io/cocoapods/l/FGIAPService.svg?style=flat)](https://cocoapods.org/pods/FGIAPService)
[![Platform](https://img.shields.io/cocoapods/p/FGIAPService.svg?style=flat)](https://cocoapods.org/pods/FGIAPService)

一套用于解决苹果IAP的解决方案，支持自动续费订阅，适用于希望自己架设服务器进行验证的开发者, 能够非常简单快速地接入到项目中

[更详细的介绍](https://juejin.cn/post/6963969762703605791)

## 已解决问题
- 窜单
- 漏单
- 账号切换
- apple验证
- 票据异常
- 数据丢失


## 安装

### CocoaPods

1. 在 Podfile 中添加 `pod 'FGIAPService'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 `<FGIAPService/FGIAPService.h>`。

若搜索不到库，可使用 rm ~/Library/Caches/CocoaPods/search_index.json 移除本地索引然后再执行安装，或者更新一下 CocoaPods 版本。

### 手动导入

1. 下载 FGIAPService 文件夹所有内容并且拖入你的工程中。
2. 导入 `FGIAPService.h`。


## 用法

### 基本使用

在已经申请消耗性商品的前提下，只需要通过3个步骤就能简单使用`FGIAPService`完成消耗性商品的购买

##### 1. 配置服务器校验代理对象

需要配置一个遵守<FGIAPVerifyTransaction>协议的对象，来完成跟服务器订单状态同步，建议在APP一启动的时候就开始配置（也可以在登录成功后）。
```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[FGIAPManager shared] setConfigureWith: id<FGIAPVerifyTransaction>];
    
}
```


##### 2. 通过苹果商品列表

初始化一个FGIAPProductsFilter对象来获取SKProduct列表
```
FGIAPProductsFilter *filter = [[FGIAPProductsFilter alloc] init];

[filter requestProductsWith:[[NSSet alloc] initWithArray:@[product.productId]] completion:^(NSArray<SKProduct *> * _Nonnull products) { }];
```

##### 3. 支付购买

完成SKProduct商品的支付并返回支付结果
```
[[FGIAPManager shared].iap buyProduct:product onCompletion:^(NSString * _Nonnull message, FGIAPManagerPurchaseRusult result) { }];
```


## 问题交流
如果大家发现bug或者需求，请在GitHub提issue    
好用的话，请路过的朋友们给点个star 🙏🙏🙏🙏🙏



## 友情分享 

[FGPopupScheduler](https://github.com/FoneG/FGPopupScheduler)：     ✨ ✨ ✨ ✨ iOS弹窗调用器，控制弹窗按照指定的策略进行显示。Helps you control popups easily. ✨ ✨ ✨ ✨
