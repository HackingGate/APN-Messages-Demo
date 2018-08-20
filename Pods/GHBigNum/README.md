GHBigNum
===========

BigNum library for Objective-C. Uses OpenSSL.

# Install

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects.

## Podfile

```ruby
platform :ios, "7.0"
pod "GHBigNum"
```

This only includes a few bignum methods that I needed, so its still a work in progress.

## a^p % m

```objc
GHBigNum *a = [GHBigNum bigNumWithDecimalString:@"3487438743234789234879"];
GHBigNum *p = [GHBigNum bigNumWithDecimalString:@"22"];
GHBigNum *m = [GHBigNum bigNumWithDecimalString:@"43234789234880"];
GHBigNum *r = [GHBigNum modPow:a p:p m:m];
```

## (a*r) % m == 1

```objc
GHBigNum *a = [GHBigNum bigNumWithDecimalString:@"3487438743234789234879"];
GHBigNum *m = [GHBigNum bigNumWithDecimalString:@"743234789234880"];
GHBigNum *r = [GHBigNum modInverse:a m:m];
```


## Prime

```objc
GHBigNum *bn = [GHBigNum generatePrime:512];
[bn isPrime]; // YES
```

