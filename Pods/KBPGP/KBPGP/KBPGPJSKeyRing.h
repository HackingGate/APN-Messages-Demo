//
//  KBPGPJSKeyRing.h
//  KBPGP
//
//  Created by Gabriel on 7/31/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <KBKeybase/KBKey.h>
#import <KBKeybase/KBKeyRing.h>

#import <JavaScriptCore/JavaScriptCore.h>

typedef void (^KBKeyRingPasswordCompletionBlock)(NSArray *bundles);
typedef void (^KBKeyRingPasswordBlock)(NSArray *secretKeys, KBKeyRingPasswordCompletionBlock completion);

@protocol KBKeyRingsExport <JSExport>
JSExportAs(fetch,
- (void)fetch:(NSArray *)keyIds ops:(NSUInteger)ops success:(JSValue *)success failure:(JSValue *)failure
);
@end

/*!
 Crypto key ring implementation.
 */
@interface KBPGPJSKeyRing : NSObject <KBKeyRingsExport>

@property dispatch_queue_t completionQueue;
@property (copy) KBKeyRingPasswordBlock passwordBlock;

- (id)initWithKeyRing:(id<KBKeyRing>)keyRing;

@end
