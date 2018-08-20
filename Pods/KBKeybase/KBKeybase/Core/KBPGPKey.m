//
//  KBPGPKey.m
//  KBCrypto
//
//  Created by Gabriel on 8/14/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "KBPGPKey.h"

#import <GHKit/GHKit.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <TSTripleSec/TSTripleSec.h>

NSString *NSStringFromKBPGPKeyFlags(KBPGPKeyFlags flags) {
  NSMutableArray *desc = [NSMutableArray array];
  if ((flags & KBPGPKeyFlagsSignData) != 0) [desc addObject:@"Sign"];
  if ((flags & KBPGPKeyFlagsEncryptComm) != 0) [desc addObject:@"Encrypt (Comm)"];
  if ((flags & KBPGPKeyFlagsEncryptStorage) != 0) [desc addObject:@"Encrypt (Storage)"];
  if ((flags & KBPGPKeyFlagsCertifyKeys) != 0) [desc addObject:@"Certify"];
  if ((flags & KBPGPKeyFlagsAuth) != 0) [desc addObject:@"Auth"];
  if ((flags & KBPGPKeyFlagsShared) != 0) [desc addObject:@"Shared"];
  return [desc componentsJoinedByString:@", "];
}

KBKeyCapabilities KBKeyCapabiltiesFromFlags(KBPGPKeyFlags flags) {
  KBKeyCapabilities capabilities = 0;
  if ((flags & KBPGPKeyFlagsEncryptComm) != 0) capabilities |= (KBKeyCapabilitiesEncrypt | KBKeyCapabilitiesDecrypt);
  if ((flags & KBPGPKeyFlagsEncryptStorage) != 0) capabilities |= (KBKeyCapabilitiesEncrypt | KBKeyCapabilitiesDecrypt);
  if ((flags & KBPGPKeyFlagsSignData) != 0) capabilities |= (KBKeyCapabilitiesSign | KBKeyCapabilitiesVerify);
  return capabilities;
}

@implementation KBPGPKey

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
           @"fingerprint": @"fingerprint",
           @"publicKeyBundle": @"public_key_bundle",
           @"keyId": @"pgp_key_id",
           @"numBits": @"nbits",
           @"flags": @"flags",
           @"algorithm": @"type",
           @"date": @"timestamp",
           @"selfSigned": @"self_signed",
           @"subKeys": @"subkeys",
           @"userIds": @"userids",
           //@"dateModified": NSNull.null,
           //@"secretKeyArmoredEncrypted": NSNull.null,
           };
}

+ (NSValueTransformer *)dateJSONTransformer {
  return [MTLValueTransformer transformerUsingForwardBlock:^(NSDate *date, BOOL *success, NSError **error) {
    return [NSDate gh_parseTimeSinceEpoch:date];
  } reverseBlock:^(NSDate *date, BOOL *success, NSError **error) {
    return [NSNumber numberWithUnsignedLongLong:[date timeIntervalSince1970]];
  }];
}

+ (NSValueTransformer *)subKeysJSONTransformer {
  return [MTLJSONAdapter arrayTransformerWithModelClass:KBPGPSubKey.class];
}

+ (NSValueTransformer *)userIdsJSONTransformer {
  return [MTLJSONAdapter arrayTransformerWithModelClass:KBPGPUserId.class];
}

- (KBKeyCapabilities)capabilities {
  KBKeyCapabilities capabilities = KBKeyCapabiltiesFromFlags(_flags);
  for (KBPGPSubKey *subKey in _subKeys) {
    capabilities |= subKey.capabilities;
  }
  return capabilities;
}

- (KBPGPUserId *)primaryUserId {
  if ([_userIds count] == 0) return nil;

  for (KBPGPUserId *userId in _userIds) {
    if (userId.primary) return userId;
  }
  return _userIds[0];
}

- (NSString *)displayDescription {
  NSString *displayDescription = [self.primaryUserId userIdDescription:@" "];
  if (!displayDescription) displayDescription = self.fingerprint;
  return displayDescription;
}

- (NSArray *)alternateUserIds {
  NSMutableArray *alternateUserIds = [_userIds mutableCopy];
  [alternateUserIds removeObject:[self primaryUserId]];
  return alternateUserIds;
}

- (NSString *)typeDescription {
  if (self.secretKey) {
    return @"Secret Key";
  } else {
    return @"Public Key";
  }
}

- (NSString *)decryptSecretKeyArmoredWithPassword:(NSString *)password error:(NSError * __autoreleasing *)error {
  if (!_secretKeyArmoredEncrypted) return nil;
  TSTripleSec *tripleSec = [[TSTripleSec alloc] init];
  NSData *data = [tripleSec decrypt:_secretKeyArmoredEncrypted key:[password dataUsingEncoding:NSUTF8StringEncoding] error:error];
  if (!data) return nil;
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSArray *)keyIds {
  NSMutableArray *keyIds = [NSMutableArray array];
  [keyIds addObject:[self.keyId lowercaseString]];
  if (_subKeys) [keyIds addObjectsFromArray:[_subKeys map:^id(KBPGPSubKey *subKey) { return [subKey.keyId lowercaseString]; }]];
  return keyIds;
}

- (BOOL)hasKeyId:(NSString *)keyId {
  return !![self.keyIds detect:^BOOL(NSString *k) {
    return [k isEqual:keyId];
  }];
}

- (BOOL)hasEmail:(NSString *)email {
  return !![_userIds detect:^BOOL(KBPGPUserId *userId) {
    return [userId.email isEqual:email];
  }];
}

- (NSComparisonResult)compare:(KBPGPKey *)key2 {
  KBPGPUserId *userId1 = [self primaryUserId];
  KBPGPUserId *userId2 = [key2 primaryUserId];
  if (userId1.userName) {
    if (!userId2) return NSOrderedAscending;
    return [userId1.userName localizedCaseInsensitiveCompare:userId2.userName];
  } else if (userId2) {
    return NSOrderedDescending;
  }
  return [self.fingerprint caseInsensitiveCompare:key2.fingerprint];
}

+ (instancetype)PGPKeyFromDictionary:(NSDictionary *)dict error:(NSError **)error {
  return [MTLJSONAdapter modelOfClass:KBPGPKey.class fromJSONDictionary:dict error:error];
}

@end

@implementation KBPGPSubKey

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
           @"keyId": @"pgp_key_id",
           @"numBits": @"nbits",
           @"flags": @"flags",
           @"algorithm": @"type",
           @"date": @"timestamp",
           };
}

+ (NSValueTransformer *)dateJSONTransformer {
  return [MTLValueTransformer transformerUsingForwardBlock:^(NSDate *date, BOOL *success, NSError **error) {
    return [NSDate gh_parseTimeSinceEpoch:date];
  } reverseBlock:^(NSDate *date, BOOL *success, NSError **error) {
    return [NSNumber numberWithUnsignedLongLong:[date timeIntervalSince1970]];
  }];
}

- (NSString *)subKeyDescription {
  //NSStringFromKBPGPKeyFlags(_flags),
  return [NSString stringWithFormat:@"%@\n%d %@\n%@", [_keyId uppercaseString], (int)_numBits, NSStringFromKBKeyAlgorithm(_algorithm), NSStringFromKBKeyCapabilities([self capabilities])];
}

- (KBKeyCapabilities)capabilities {
  return KBKeyCapabiltiesFromFlags(_flags);
}

@end


@interface KBPGPUserId ()
@property NSString *userName;
@property NSString *email;
@end

@implementation KBPGPUserId

+ (KBPGPUserId *)userIdWithUserName:(NSString *)userName email:(NSString *)email {
  KBPGPUserId *userId = [[KBPGPUserId alloc] init];
  userId.userName = userName;
  userId.email = email;
  return userId;
}

+ (KBPGPUserId *)userIdForKeybaseUserName:(NSString *)keybaseUserName {
  return [self userIdWithUserName:NSStringWithFormat(@"keybase.io/%@", keybaseUserName) email:NSStringWithFormat(@"%@@keybase.io", keybaseUserName)];
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{
           @"userName": @"username",
           @"email": @"email",
           @"primary": @"primary",
           };
}

- (NSString *)RFC822 {
  if ([_userName gh_isPresent] && [_email gh_isPresent]) {
    return NSStringWithFormat(@"%@ <%@>", _userName, _email);
  } else if ([_userName gh_isPresent]) {
    return _userName;
  } else if ([_email gh_isPresent]) {
    return _email;
  } else {
    return @"";
  }
}

- (NSString *)userIdDescription:(NSString *)joinedByString {
  NSMutableArray *desc = [NSMutableArray array];
  if (_userName) [desc addObject:_userName];
  if (_email) [desc addObject:_email];
  if ([desc count] == 0) return nil;
  return [desc componentsJoinedByString:joinedByString];
}

@end