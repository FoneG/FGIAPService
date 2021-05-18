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
@property (nonatomic, assign) BOOL request;
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
    FGLog(@"@@## FGIAPProductKeyChainStore update tradeNo: %@ productIdentifier:%@",  tradeNo, productIdentifier);
}

- (NSString *)requestOneOrderWithProduct:(NSString *)productIdentifier{
    NSString *target = nil;
    if ([productIdentifier FG_isNSStringAndNotEmpty]) {
        __block FGIAPKeyChainStoreItem *one = nil;
        [self.items enumerateObjectsUsingBlock:^(FGIAPKeyChainStoreItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.productIdentifier isEqualToString:productIdentifier]) {
                one = obj;
                one.request = YES;
                *stop = YES;
            }
        }];
        target = one.tradeNO;
    }
    FGLog(@"@@## FGIAPProductKeyChainStore requestOneOrderWithProduct requestOneOrderWithProduct: %@ target:%@", productIdentifier, target);
    return target;
}

- (void)removeOrder:(NSString *)orderId{
    [self.store removeItemForKey:orderId];
}

- (void)removeALLOrder{
    [self.store removeAllItems];
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
        _request = NO;
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
    [data setValue:@(_request) forKey:@"request"];
    return [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:nil];;
}

- (void)setJsonData:(NSDictionary *)jsonObject{
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonObject
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if (dic) {
        _tradeNO = [dic valueForKey:@"tradeNO"];
        _productIdentifier = [dic valueForKey:@"productIdentifier"];
        _request = [[dic valueForKey:@"request"] boolValue];
    }
}

@end


