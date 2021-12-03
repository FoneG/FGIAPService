//
//  FGIAPManager.h
//  MaltBaby
//
//  Created by FoneG on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import "FGIAPService.h"

NS_ASSUME_NONNULL_BEGIN

@interface FGIAPManager : NSObject

/// FGIAPService
@property (nonatomic, strong, readonly) FGIAPService *iap;

/// Initialize
+ (FGIAPManager *)shared;

/// Configure a server validation object
/// @param verifyTransaction a server validation object
- (void)setConfigureWith:(id<FGIAPVerifyTransaction>)verifyTransaction;

@end

NS_ASSUME_NONNULL_END
