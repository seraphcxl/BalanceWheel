//
//  DCJSONFile.h
//  BalanceWheel
//
//  Created by Derek Chen on 11/18/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tourbillon/DCTourbillon.h"

extern NSString *kDCJSONFileNameSeparator;
extern NSString *kDCJSONFileIdentifier;
extern NSString *kDCJSONFileExtension;

extern NSUInteger kDCJSONFileEncryptBlockLength;

@interface DCJSONFile : NSObject

@property (assign, nonatomic, readonly, getter=isEncrypted) BOOL encrypted;

- (BOOL)initWithContents:(NSString *)filePath shouldEncrypt:(BOOL)shouldEncrypt;
- (BOOL)isInited;
- (BOOL)synchronize;

- (NSString *)filePath;

- (BOOL)resetFile:(NSDictionary *)resetDictionary;

- (id)objectForKey:(NSString *)key;
- (void)setObject:(id)value forKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (NSString *)stringForKey:(NSString *)key;
- (NSArray *)arrayForKey:(NSString *)key;
- (NSDictionary *)dictionaryForKey:(NSString *)key;
- (NSData *)dataForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;
- (NSURL *)URLForKey:(NSString *)key;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

@end
