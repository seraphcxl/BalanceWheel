//
//  DCJSONFile.m
//  BalanceWheel
//
//  Created by Derek Chen on 11/18/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import "DCJSONFile.h"

NSString *kDCJSONFileNameSeparator = @".";
NSString *kDCJSONFileIdentifier = @"DCJSONFile";
NSString *kDCJSONFileExtension = @"jef";  // JOSN encrypted file

NSUInteger kDCJSONFileEncryptBlockLength = 256;

@interface DCJSONFile () {
}

@property (copy, nonatomic) NSString *storeFilePath;
@property (strong, nonatomic) NSMutableDictionary *rootDict;
@property (assign, nonatomic) BOOL encrypted;

+ (NSMutableArray *)keyStr2KeyArray:(NSString *)keyStr;
+ (NSString *)queryStoreFilePath;

@end

@implementation DCJSONFile

@synthesize storeFilePath = _storeFilePath;
@synthesize rootDict = _rootDict;
@synthesize encrypted = _encrypted;

+ (NSMutableArray *)keyStr2KeyArray:(NSString *)keyStr {
    NSMutableArray *result = nil;
    do {
        if (!keyStr) {
            break;
        }
        result = [NSMutableArray array];
        NSScanner *scanner = [NSScanner scannerWithString:keyStr];
        NSString *key = nil;
        while(![scanner isAtEnd]) {
            [scanner scanUpToString:kDCJSONFileNameSeparator intoString:&key];
            [scanner scanString:kDCJSONFileNameSeparator intoString:NULL];
            [result addObject:key];
        }
    } while (NO);
    return result;
}

+ (NSString *)queryStoreFilePath {
    NSString *result = nil;
    NSOutputStream *output = nil;
    do {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        if (paths.count == 0) {
            break;
        }
        
        NSString *identifier = [[NSBundle mainBundle] bundleIdentifier];
        if (!identifier) {
            identifier = kDCJSONFileIdentifier;
        }
        
        NSString *dir = [(NSString *)[paths objectAtIndex:0] stringByAppendingPathComponent:identifier];
        
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        BOOL isDir = NO;
        if (![fileMgr fileExistsAtPath:dir isDirectory:&isDir] || !isDir) {
            NSError *err = nil;
            if (![fileMgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:&err] || err) {
                NSLog(@"%@", [err localizedDescription]);
                break;
            }
        }
        
        NSString *path = [[dir stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:kDCJSONFileExtension];
        
        isDir = NO;
        if (![fileMgr fileExistsAtPath:path isDirectory:&isDir] || isDir) {
            output = [NSOutputStream outputStreamToFileAtPath:path append:NO];
            [output open];
            
            NSDictionary *emptyDict = [NSDictionary dictionary];
            
            NSError *err = nil;
            NSUInteger resultCount = [NSJSONSerialization writeJSONObject:emptyDict toStream:output options:0 error:&err];
            if (resultCount == 0 || err) {
                NSLog(@"%@", [err localizedDescription]);
                break;
            }
        }
        
        result = path;
    } while (NO);
    [output close];
    output = nil;
    return result;
}

- (id)init {
    self = [super init];
    if (self) {
        ;
    }
    return self;
}

- (void)dealloc {
    do {
        [self.rootDict threadSafe_removeAllObjects];
        self.rootDict = nil;
        
        self.storeFilePath = nil;
    } while (NO);
}

- (BOOL)initWithContents:(NSString *)filePath shouldEncrypt:(BOOL)shouldEncrypt {
    BOOL result = NO;
    NSInputStream *input = nil;
    NSOutputStream *output = nil;
    NSString *pathForDecrypt = nil;
    do {
        if (self.storeFilePath && self.rootDict) {
            [self synchronize];
        }
        self.storeFilePath = nil;
        _encrypted = shouldEncrypt;
        if (filePath) {
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            BOOL isDir = NO;
            if ([fileMgr fileExistsAtPath:filePath isDirectory:&isDir] && !isDir) {
                self.storeFilePath = filePath;
            } else {
                output = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
                [output open];
                
                NSDictionary *emptyDict = [NSDictionary dictionary];
                
                NSError *err = nil;
                NSUInteger resultCount = [NSJSONSerialization writeJSONObject:emptyDict toStream:output options:0 error:&err];
                if (resultCount == 0 || err) {
                    NSLog(@"%@", [err localizedDescription]);
                    break;
                }
                [output close];
                output = nil;
                
                if (_encrypted) {
                    if (![DCXOREncryptUtility encryptFile:filePath toPath:filePath withBlockLength:kDCJSONFileEncryptBlockLength]) {
                        break;
                    }
                }
                
                self.storeFilePath = filePath;
            }
        }
        
        if (!self.storeFilePath) {
            self.storeFilePath = [DCJSONFile queryStoreFilePath];
        }
        
        if (_encrypted) {
            pathForDecrypt = [NSString stringWithFormat:@"%@_%@", self.storeFilePath, [NSObject createUniqueStrByUUID]];
            if (![DCXOREncryptUtility decryptFile:self.storeFilePath toPath:pathForDecrypt withBlockLength:kDCJSONFileEncryptBlockLength]) {
                break;
            }
            input = [NSInputStream inputStreamWithFileAtPath:pathForDecrypt];
        } else {
            input = [NSInputStream inputStreamWithFileAtPath:self.storeFilePath];
        }
        
        [input open];
        
        NSError *err = nil;
        self.rootDict = [NSJSONSerialization JSONObjectWithStream:input options:NSJSONReadingMutableContainers error:&err];
        if (!self.rootDict || err) {
            NSLog(@"%@", [err localizedDescription]);
            break;
        }
        
        [self.rootDict threadSafe_init];
        
        result = YES;
    } while (NO);
    
    [output close];
    output = nil;
    
    [input close];
    input = nil;
    
    if (pathForDecrypt) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSError *err = nil;
        if ([fileMgr fileExistsAtPath:pathForDecrypt]) {
            if (![fileMgr removeItemAtPath:pathForDecrypt error:&err] || err) {
                NSLog(@"%@", [err localizedDescription]);
            }
        }
    }
    
    return result;
}

- (BOOL)isInited {
    return self.rootDict ? YES : NO;
}

- (BOOL)synchronize {
    BOOL result = NO;
    NSOutputStream *output = nil;
    do {
        output = [NSOutputStream outputStreamToFileAtPath:self.storeFilePath append:NO];
        [output open];
        
        NSError *err = nil;
        NSUInteger resultCount = [NSJSONSerialization writeJSONObject:self.rootDict toStream:output options:0 error:&err];
        if (resultCount == 0 || err) {
            NSLog(@"%@", [err localizedDescription]);
            break;
        }
        
        if (_encrypted) {
            [output close];
            output = nil;
            
            if (![DCXOREncryptUtility encryptFile:self.storeFilePath toPath:self.storeFilePath withBlockLength:kDCJSONFileEncryptBlockLength]) {
                break;
            }
        }
        
        result = YES;
    } while (NO);
    [output close];
    output = nil;
    return result;
}

- (NSString *)filePath {
    return self.storeFilePath;
}

- (BOOL)resetFile:(NSDictionary *)resetDictionary {
    BOOL result = NO;
    do {
        if (!resetDictionary) {
            resetDictionary = [NSDictionary dictionary];
        }
        
        self.rootDict = [[NSMutableDictionary dictionaryWithDictionary:resetDictionary] threadSafe_init];
        
        if (![self synchronize]) {
            break;
        }
        
        if (![self initWithContents:self.storeFilePath shouldEncrypt:_encrypted]) {
            break;
        }
        
        result = YES;
    } while (NO);
    return result;
}

- (id)objectForKey:(NSString *)key {
    id result = nil;
    do {
        if (!key) {
            break;
        }
        NSArray *keyAry = [DCJSONFile keyStr2KeyArray:key];
        NSUInteger keyAryCount = keyAry.count;
        NSMutableDictionary *currentDict = self.rootDict;
        for (NSUInteger idx = 0; currentDict && !result && idx < keyAryCount; ++idx) {
            NSString *key = [keyAry objectAtIndex:idx];
            if (idx == (keyAryCount - 1)) {
                result = [[currentDict threadSafe_objectForKey:key] copy];
            } else {
                currentDict = [[currentDict threadSafe_objectForKey:key] threadSafe_init];
            }
        }
    } while (NO);
    return result;
}

- (void)setObject:(id)value forKey:(NSString *)key {
    do {
        if (!value || !key) {
            break;
        }
        NSArray *keyAry = [DCJSONFile keyStr2KeyArray:key];
        NSUInteger keyAryCount = keyAry.count;
        NSMutableDictionary *currentDict = self.rootDict;
        for (NSUInteger idx = 0; idx < keyAryCount; ++idx) {
            NSString *key = [keyAry objectAtIndex:idx];
            if (idx == (keyAryCount - 1)) {
                [currentDict threadSafe_setObject:value forKey:key];
            } else {
                NSMutableDictionary *tmpDict = [currentDict threadSafe_objectForKey:key];
                if (!tmpDict) {
                    tmpDict = [NSMutableDictionary dictionary];
                    [currentDict threadSafe_setObject:tmpDict forKey:key];
                }
                currentDict = [tmpDict threadSafe_init];
            }
        }
    } while (NO);
}

- (void)removeObjectForKey:(NSString *)key {
    do {
        if (!key) {
            break;
        }
        NSArray *keyAry = [DCJSONFile keyStr2KeyArray:key];
        NSUInteger keyAryCount = keyAry.count;
        NSMutableDictionary *currentDict = self.rootDict;
        for (NSUInteger idx = 0; currentDict && idx < keyAryCount; ++idx) {
            NSString *key = [keyAry objectAtIndex:idx];
            if (idx == (keyAryCount - 1)) {
                [currentDict threadSafe_removeObjectForKey:key];
            } else {
                currentDict = [[currentDict threadSafe_objectForKey:key] threadSafe_init];
            }
        }
    } while (NO);
}

- (NSString *)stringForKey:(NSString *)key {
    NSString *result = nil;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSString class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSArray *)arrayForKey:(NSString *)key {
    NSArray *result = nil;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSArray class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSDictionary *)dictionaryForKey:(NSString *)key {
    NSDictionary *result = nil;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSDictionary class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSData *)dataForKey:(NSString *)key {
    NSData *result = nil;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSData class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSInteger)integerForKey:(NSString *)key {
    NSInteger result = 0;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp integerValue];
    } while (NO);
    return result;
}

- (float)floatForKey:(NSString *)key {
    float result = 0.0f;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp floatValue];
    } while (NO);
    return result;
}

- (double)doubleForKey:(NSString *)key {
    double result = 0.0f;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp doubleValue];
    } while (NO);
    return result;
}

- (BOOL)boolForKey:(NSString *)key {
    BOOL result = NO;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp boolValue];
    } while (NO);
    return result;
}

- (NSURL *)URLForKey:(NSString *)key {
    NSURL *result = nil;
    do {
        if (!key) {
            break;
        }
        id tmp = [self objectForKey:key];
        if (![tmp isKindOfClass:[NSURL class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    do {
        if (!key) {
            break;
        }
        NSNumber *num = [NSNumber numberWithInteger:value];
        [self setObject:num forKey:key];
    } while (NO);
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    do {
        if (!key) {
            break;
        }
        NSNumber *num = [NSNumber numberWithFloat:value];
        [self setObject:num forKey:key];
    } while (NO);
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    do {
        if (!key) {
            break;
        }
        NSNumber *num = [NSNumber numberWithDouble:value];
        [self setObject:num forKey:key];
    } while (NO);
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    do {
        if (!key) {
            break;
        }
        NSNumber *num = [NSNumber numberWithBool:value];
        [self setObject:num forKey:key];
    } while (NO);
}

@end
