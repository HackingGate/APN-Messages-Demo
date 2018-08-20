//
//  GHIBigNum.m
//  GHBigNum
//
//  Created by Gabriel on 11/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "GHIBigNum.h"

#import <openssl/bn.h>
#import <openssl/rand.h>
#import <Security/SecRandom.h>

@interface GHBigNum ()
@property BIGNUM *bigNum;
@end

@implementation GHBigNum

- (instancetype)initWithBigNumNoCopy:(BIGNUM *)bigNum {
  if ((self = [self init])) {
    _bigNum = bigNum;
  }
  return self;
}

- (instancetype)initWithDecimalString:(NSString *)decimalString {
  if ((self = [self init])) {
    _bigNum = BN_new();
    BN_dec2bn(&_bigNum, [decimalString cStringUsingEncoding:NSASCIIStringEncoding]);
  }
  return self;
}

+ (instancetype)bigNumWithDecimalString:(NSString *)decimalString {
  return [[self alloc] initWithDecimalString:decimalString];
}

- (void)dealloc {
  if (_bigNum) {
    BN_free(_bigNum);
    _bigNum = nil;
  }
}

- (NSString *)description {
  return [self decimalString];
}

- (NSString *)decimalString {
  if (!_bigNum) return nil;
  char *h = BN_bn2dec(_bigNum);
  return [NSString stringWithUTF8String:h];
}

+ (void)ensureSeed {
  // OpenSSL is using /dev/urandom to seed itself autotmatically but
  // lets use the Security framework to do it which is guaranteed to be /dev/urandom (or better).
  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    NSMutableData *data = [NSMutableData dataWithLength:520];
    int ret = SecRandomCopyBytes(kSecRandomDefault, 520, [data mutableBytes]);
    if (ret == -1) {
      [NSException raise:NSInternalInconsistencyException format:@"Couldn't seed"];
      return;
    }
    RAND_seed([data bytes], (int)[data length]);
  });
}

- (BOOL)isPrime {
  BN_CTX *ctx = BN_CTX_new();
  int r = BN_is_prime(_bigNum, BN_prime_checks, NULL, ctx, NULL);
  BN_CTX_free(ctx);
  return (r == 1);
}

+ (GHBigNum *)generatePrime:(int)bits {
  [self ensureSeed];
  
  BIGNUM *r = BN_new();
  BN_generate_prime_ex(r, bits, 0, NULL, NULL, NULL);
  return [[GHBigNum alloc] initWithBigNumNoCopy:r];
}

+ (GHBigNum *)modPow:(GHBigNum *)a p:(GHBigNum *)p m:(GHBigNum *)m {
  BN_CTX *ctx = BN_CTX_new();
  BIGNUM *r = BN_new();
  BN_mod_exp(r, a.bigNum, p.bigNum, m.bigNum, ctx);
  BN_CTX_free(ctx);
  return [[GHBigNum alloc] initWithBigNumNoCopy:r];
}

+ (GHBigNum *)modInverse:(GHBigNum *)a m:(GHBigNum *)m {
  BN_CTX *ctx = BN_CTX_new();
  BIGNUM *r = BN_new();
  BN_mod_inverse(r, a.bigNum, m.bigNum, ctx);
  BN_CTX_free(ctx);
  return [[GHBigNum alloc] initWithBigNumNoCopy:r];
}

- (BOOL)isEqual:(id)obj {
  return ((!_bigNum && ![obj bigNum]) || BN_cmp([obj bigNum], _bigNum) == 0);
}

@end
