//
//  KBPGPMessage.m
//  KBCrypto
//
//  Created by Gabriel on 9/19/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import "KBPGPMessage.h"

#import <ObjectiveSugar/ObjectiveSugar.h>
#import <GHKit/GHKit.h>

@interface KBPGPMessage ()
@property NSArray *verifyKeyIds;
@property NSArray *decryptKeyIds;
@property NSString *bundle;
@property NSArray *signers;
@property NSArray *warnings;

@property (nonatomic) NSString *text;
@end

@implementation KBPGPMessage

+ (KBPGPMessage *)messageWithVerifyKeyIds:(NSArray *)verifyKeyIds decryptKeyIds:(NSArray *)decryptKeyIds bundle:(NSString *)bundle data:(NSData *)data signers:(NSArray *)signers warnings:(NSArray *)warnings {
  KBPGPMessage *message = [[KBPGPMessage alloc] init];
  message.verifyKeyIds = verifyKeyIds;
  message.decryptKeyIds = decryptKeyIds;
  message.bundle = bundle;
  message.data = data;
  message.signers = signers;
  message.warnings = warnings;
  return message;
}

- (NSString *)text {
  if (_text) return _text;
  if (!_data) return nil;
  // TODO: It's a security issue to assume UTF8
  _text = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
  if (!_text) {
    GHErr(@"Unable to decode data into string (%@)", @(_data.length));

    // TODO: This is a hack and is dangerous
    _text = [[NSString alloc] initWithData:_data encoding:NSWindowsCP1252StringEncoding];
    if (!_text) _text = [[NSString alloc] initWithData:_data encoding:NSISOLatin1StringEncoding];
  }

  if (!_text) {
    if (!_warnings) _warnings = [NSArray array];
    _warnings = [_warnings arrayByAddingObject:@"Unable to decode data."];
  }
  return _text;
}

- (void)verifiedWithSigners:(NSArray *)signers warnings:(NSArray *)warnings verifyKeyIds:(NSArray *)verifyKeyIds {
  _signers = [@[(_signers ? _signers : @[]), (signers ? signers : @[])] flatten];
  _warnings = [@[(_warnings ? _warnings : @[]), (warnings ? warnings : @[])] flatten];
  _verifyKeyIds = [@[(_verifyKeyIds ? _warnings : @[]), (verifyKeyIds ? verifyKeyIds : @[])] flatten];
}

#pragma mark NSCoding

+ (BOOL)supportsSecureCoding { return YES; }

- (id)initWithCoder:(NSCoder *)decoder {
  if ((self = [self init])) {
    _verifyKeyIds = [decoder decodeObjectOfClass:NSArray.class forKey:@"verifyKeyIds"];
    _decryptKeyIds = [decoder decodeObjectOfClass:NSArray.class forKey:@"decryptKeyIds"];
    _bundle = [decoder decodeObjectOfClass:NSString.class forKey:@"bundle"];
    _data = [decoder decodeObjectOfClass:NSData.class forKey:@"data"];
    _signers = [decoder decodeObjectOfClass:NSArray.class forKey:@"signers"];
    _warnings = [decoder decodeObjectOfClass:NSArray.class forKey:@"warnings"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:_verifyKeyIds forKey:@"verifyKeyIds"];
  [encoder encodeObject:_decryptKeyIds forKey:@"decryptKeyIds"];
  [encoder encodeObject:_bundle forKey:@"bundle"];
  [encoder encodeObject:_data forKey:@"data"];
  [encoder encodeObject:_signers forKey:@"signers"];
  [encoder encodeObject:_warnings forKey:@"warnings"];
}

@end
