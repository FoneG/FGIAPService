//
//  FGIAPServiceUtility.h
//  Pods
//
//  Created by FoneG on 2021/5/10.
//

#ifndef FGIAPServiceUtility_h
#define FGIAPServiceUtility_h

//#define MRDEBUG

#if defined (FGDEBUG) && defined (DEBUG)
    #define FGLog(...) NSLog(__VA_ARGS__)
#else
    #define FGLog(...)
#endif

#define WS(wSelf) __weak typeof(self) wSelf = self
#define FGIAPServerOverdueErrorCode 11000007

#endif /* FGIAPServiceUtility_h */
