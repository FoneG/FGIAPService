//
//  FGIAPManager.m
//  MaltBaby
//
//  Created by FoneG on 2020/5/11.
//

#import "FGIAPManager.h"

@implementation FGIAPManager

+ (FGIAPManager *)shared{
    static FGIAPManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[FGIAPManager alloc] init];
    });
    return manager;
}

- (void)setConfigureWith:(id<FGIAPVerifyTransaction>)verifyTransaction{
    self->_iap = [[FGIAPService alloc] initWithTransaction:verifyTransaction];
}


@end
