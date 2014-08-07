//
//  DCJSONUserDefault.h
//  BalanceWheel
//
//  Created by Derek Chen on 8/6/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Tourbillon/DCTourbillon.h"

extern NSString *kDCJSONUserDefaultNameSeparator;
extern NSString *kDCJSONUserDefaultIdentifier;
extern NSString *kDCJSONUserDefaultExtension;

@interface DCJSONUserDefault : NSObject {
}

DEFINE_SINGLETON_FOR_HEADER(DCJSONUserDefault)

- (BOOL)initContents:(NSString *)filePath;
- (BOOL)isInited;
- (BOOL)synchronize;

- (NSString *)filePath;

- (BOOL)registerDefaults:(NSDictionary *)registrationDictionary;

- (id)objectForKey:(NSString *)defaultName;
- (void)setObject:(id)value forKey:(NSString *)defaultName;
- (void)removeObjectForKey:(NSString *)defaultName;

- (NSString *)stringForKey:(NSString *)defaultName;
- (NSArray *)arrayForKey:(NSString *)defaultName;
- (NSDictionary *)dictionaryForKey:(NSString *)defaultName;
- (NSData *)dataForKey:(NSString *)defaultName;
- (NSInteger)integerForKey:(NSString *)defaultName;
- (float)floatForKey:(NSString *)defaultName;
- (double)doubleForKey:(NSString *)defaultName;
- (BOOL)boolForKey:(NSString *)defaultName;
- (NSURL *)URLForKey:(NSString *)defaultName;

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;
- (void)setFloat:(float)value forKey:(NSString *)defaultName;
- (void)setDouble:(double)value forKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forKey:(NSString *)defaultName;

@end
