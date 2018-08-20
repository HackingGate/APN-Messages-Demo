//
//  GHIBigNum.h
//  GHBigNum
//
//  Created by Gabriel on 11/3/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <openssl/bn.h>

@interface GHBigNum : NSObject

- (instancetype)initWithBigNumNoCopy:(BIGNUM *)bigNum;
- (instancetype)initWithDecimalString:(NSString *)decimalString;
+ (instancetype)bigNumWithDecimalString:(NSString *)decimalString;

- (NSString *)decimalString;

- (BOOL)isPrime;

+ (GHBigNum *)generatePrime:(int)bits;

// r=a^p % m
+ (GHBigNum *)modPow:(GHBigNum *)a p:(GHBigNum *)p m:(GHBigNum *)m;

// inverse of a modulo m
+ (GHBigNum *)modInverse:(GHBigNum *)a m:(GHBigNum *)m;

@end
