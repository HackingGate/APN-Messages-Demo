//
//  NACounter.h
//  NACrypto
//
//  Created by Gabriel on 6/20/14.
//  Copyright (c) 2014 Gabriel Handford. All rights reserved.
//

#import <Foundation/Foundation.h>

// Counter for CTR mode
@interface NACounter : NSObject

- (instancetype)initWithData:(NSData *)data;

- (void)increment;

- (NSData *)data;

@end
