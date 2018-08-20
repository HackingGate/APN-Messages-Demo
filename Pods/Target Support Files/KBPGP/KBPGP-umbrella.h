#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "KBJSCore.h"
#import "KBKeyGenProgress.h"
#import "KBPGP.h"
#import "KBPGPJSKeyRing.h"
#import "KBPGPUtil.h"

FOUNDATION_EXPORT double KBPGPVersionNumber;
FOUNDATION_EXPORT const unsigned char KBPGPVersionString[];

