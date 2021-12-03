//
//  FGIAPTransaction.h
//  MaltBaby
//
//  Created by FoneG on 2020/5/9.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FGIAPTransaction : NSObject
@property (nonatomic, strong) SKPaymentTransaction *transaction;
@property (nonatomic, strong) NSString *receipt;
@property (nonatomic, strong) NSString *productIdentifier;
@property (nonatomic, assign) BOOL handle;
@end

NS_ASSUME_NONNULL_END
