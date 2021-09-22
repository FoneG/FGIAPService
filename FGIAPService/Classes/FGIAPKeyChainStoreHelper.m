//
//  FGIAPProductKeyChainStore.m
//  MaltBaby
//
//  Created by FoneG on 2020/5/8.
//

#import "FGIAPKeyChainStoreHelper.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "FGIAPServiceUtility.h"
#import "NSObject+FGIsNullOrEmpty.h"

static NSString *FGIAPProductKeyChainStoreService = @"__FGIAPProductKeyChainStore__";
 
@interface FGIAPKeyChainStoreItem : NSObject
@property (nonatomic, strong) NSString *tradeNO;
@property (nonatomic, strong) NSString *productIdentifier;
@property (nonatomic, assign) BOOL finish;
@property (nonatomic, assign) NSTimeInterval createTime;
@property (nonatomic, assign) NSTimeInterval finishTime;

- (instancetype)initWithTradeNo:(NSString *)tradeNO productIdentifier:(NSString *)productIdentifier;
- (instancetype)initWithString:(NSString *)jsonString;
- (NSString *)converToJsonString;
@end

@interface FGIAPKeyChainStoreHelper ()
@property (nonatomic, strong) UICKeyChainStore *store;
@property (nonatomic, strong) NSMutableArray <FGIAPKeyChainStoreItem *>*items;
@end

@implementation FGIAPKeyChainStoreHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.store = [UICKeyChainStore keyChainStoreWithService:FGIAPProductKeyChainStoreService];
                
        NSArray *allitems = [self.store allItems];
        [allitems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] && [[obj valueForKey:@"value"] isKindOfClass:[NSString class]]) {
                FGIAPKeyChainStoreItem *cache = [[FGIAPKeyChainStoreItem alloc] initWithString:[obj valueForKey:@"value"]];
                [self.items addObject:cache];
            }
        }];
    }
    return self;
}

- (void)update:(NSString *)tradeNo product:(NSString *)productIdentifier{
    if ([tradeNo FG_isNSStringAndNotEmpty] && [productIdentifier FG_isNSStringAndNotEmpty]) {
        FGIAPKeyChainStoreItem *new = [[FGIAPKeyChainStoreItem alloc] initWithTradeNo:tradeNo productIdentifier:productIdentifier];
        [self.store setString:[new converToJsonString] forKey:tradeNo];
        [self.items addObject:new];
    }
    FGLog(@"@@## FGIAPProductKeyChainStore.update tradeNo: %@ productIdentifier:%@",  tradeNo, productIdentifier);
}

- (NSString *)requestOneOrderWithProduct:(NSString *)productIdentifier{
    NSString *target = nil;
    if ([productIdentifier FG_isNSStringAndNotEmpty]) {
        __block FGIAPKeyChainStoreItem *one = nil;
        [self.items enumerateObjectsUsingBlock:^(FGIAPKeyChainStoreItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.finish && [obj.productIdentifier isEqualToString:productIdentifier]) {
                one = obj;
                *stop = YES;
            }
        }];
        target = one.tradeNO;
    }
    FGLog(@"@@## FGIAPProductKeyChainStore.requestOneOrder target:%@ productIdentifier: %@", target, productIdentifier);
    return target;
}

- (void)removeOrder:(NSString *)orderId{
    __block FGIAPKeyChainStoreItem *item = nil;
    [self.items enumerateObjectsUsingBlock:^(FGIAPKeyChainStoreItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.tradeNO isEqualToString:orderId]) {
            item = obj;
        }
    }];
    if (item) {
        [self finish:item];
    }
}

- (void)removeALLOrder{
    [self.items enumerateObjectsUsingBlock:^(FGIAPKeyChainStoreItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self finish:obj];
    }];
}

- (void)finish:(FGIAPKeyChainStoreItem *)item{
    if ([item.tradeNO FG_isNSStringAndNotEmpty]) {
        item.finish = YES;
        item.finishTime = [NSDate date].timeIntervalSince1970;
        [self.store setString:item.converToJsonString forKey:item.tradeNO];
    }
}

- (NSMutableArray<FGIAPKeyChainStoreItem *> *)items{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

@end

@implementation FGIAPKeyChainStoreItem

- (instancetype)initWithTradeNo:(NSString *)tradeNO productIdentifier:(NSString *)productIdentifier{
    if (self = [super init]) {
        _tradeNO = tradeNO;
        _productIdentifier = productIdentifier;
        _finish = NO;
        _createTime = [NSDate date].timeIntervalSince1970;
    }
    return self;
}

- (NSString *)converToJsonString{
    return [[NSString alloc] initWithData:[self jsonObject] encoding:NSUTF8StringEncoding];
}

- (instancetype)initWithString:(NSString *)jsonString{
    if (self = [super init]) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        [self setJsonData:jsonData];
    }
    return self;
}

#pragma mark - 转换为JSON

- (id)jsonObject
{
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [data setValue:_tradeNO?:@"" forKey:@"tradeNO"];
    [data setValue:_productIdentifier?:@"" forKey:@"productIdentifier"];
    [data setValue:@(_finish) forKey:@"finish"];
    [data setValue:@(_createTime) forKey:@"createTime"];
    [data setValue:@(_finishTime) forKey:@"finishTime"];
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:nil];;
}

- (void)setJsonData:(NSData *)jsonObject{
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonObject
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if (dic) {
        _tradeNO = [dic valueForKey:@"tradeNO"];
        _productIdentifier = [dic valueForKey:@"productIdentifier"];
        _finish = [[dic valueForKey:@"finish"] boolValue];
        _createTime = [[dic valueForKey:@"createTime"] doubleValue];
        _finishTime = [[dic valueForKey:@"finishTime"] doubleValue];
    }
}

@end


