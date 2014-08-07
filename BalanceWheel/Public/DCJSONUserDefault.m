//
//  DCJSONUserDefault.m
//  BalanceWheel
//
//  Created by Derek Chen on 8/6/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import "DCJSONUserDefault.h"

NSString *kDCJSONUserDefaultNameSeparator = @".";
NSString *kDCJSONUserDefaultIdentifier = @"DCJSONUserDefault";
NSString *kDCJSONUserDefaultExtension = @"jud";

@interface DCJSONUserDefault () {
}

@property (copy) NSString *storeFilePath;
@property (strong) NSMutableDictionary *rootDict;

+ (NSMutableArray *)userDefaultName2KeyArray:(NSString *)userDefaultName;
+ (NSString *)queryStoreFilePath;

@end

@implementation DCJSONUserDefault

@synthesize rootDict = _rootDict;

DEFINE_SINGLETON_FOR_CLASS(DCJSONUserDefault)

+ (NSMutableArray *)userDefaultName2KeyArray:(NSString *)userDefaultName {
    NSMutableArray *result = nil;
    do {
        if (!userDefaultName) {
            break;
        }
        result = [NSMutableArray array];
        NSScanner *scanner = [NSScanner scannerWithString:userDefaultName];
        NSString *key = nil;
        while(![scanner isAtEnd]) {
            [scanner scanUpToString:kDCJSONUserDefaultNameSeparator intoString:&key];
            [scanner scanString:kDCJSONUserDefaultNameSeparator intoString:NULL];
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
            identifier = kDCJSONUserDefaultIdentifier;
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
        
        NSString *path = [[dir stringByAppendingPathComponent:identifier] stringByAppendingPathExtension:kDCJSONUserDefaultExtension];
        
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

- (BOOL)initContents:(NSString *)filePath {
    BOOL result = NO;
    NSInputStream *input = nil;
    NSOutputStream *output = nil;
    do {
        if (self.storeFilePath && self.rootDict) {
            [self synchronize];
        }
        self.storeFilePath = nil;
        
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
                
                self.storeFilePath = filePath;
            }
        }
        
        if (!self.storeFilePath) {
            self.storeFilePath = [DCJSONUserDefault queryStoreFilePath];
        }
        
        input = [NSInputStream inputStreamWithFileAtPath:self.storeFilePath];
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
        
        result = YES;
    } while (NO);
    [output close];
    output = nil;
    return result;
}

- (NSString *)filePath {
    return self.storeFilePath;
}

- (BOOL)registerDefaults:(NSDictionary *)registrationDictionary {
    BOOL result = NO;
    do {
        if (!registrationDictionary) {
            registrationDictionary = [NSDictionary dictionary];
        }
        
        self.rootDict = [[NSMutableDictionary dictionaryWithDictionary:registrationDictionary] threadSafe_init];
        
        if (![self synchronize]) {
            break;
        }
        
        if (![self initContents:self.storeFilePath]) {
            break;
        }
        
        result = YES;
    } while (NO);
    return result;
}

- (id)objectForKey:(NSString *)defaultName {
    id result = nil;
    do {
        if (!defaultName) {
            break;
        }
        NSArray *keyAry = [DCJSONUserDefault userDefaultName2KeyArray:defaultName];
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

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    do {
        if (!value || !defaultName) {
            break;
        }
        NSArray *keyAry = [DCJSONUserDefault userDefaultName2KeyArray:defaultName];
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

- (void)removeObjectForKey:(NSString *)defaultName {
    do {
        if (!defaultName) {
            break;
        }
        NSArray *keyAry = [DCJSONUserDefault userDefaultName2KeyArray:defaultName];
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

- (NSString *)stringForKey:(NSString *)defaultName {
    NSString *result = nil;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSString class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSArray *)arrayForKey:(NSString *)defaultName {
    NSArray *result = nil;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSArray class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSDictionary *)dictionaryForKey:(NSString *)defaultName {
    NSDictionary *result = nil;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSDictionary class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSData *)dataForKey:(NSString *)defaultName {
    NSData *result = nil;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSData class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    NSInteger result = 0;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp integerValue];
    } while (NO);
    return result;
}

- (float)floatForKey:(NSString *)defaultName {
    float result = 0.0f;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp floatValue];
    } while (NO);
    return result;
}

- (double)doubleForKey:(NSString *)defaultName {
    double result = 0.0f;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp doubleValue];
    } while (NO);
    return result;
}

- (BOOL)boolForKey:(NSString *)defaultName {
    BOOL result = NO;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSNumber class]]) {
            break;
        }
        result = [(NSNumber *)tmp boolValue];
    } while (NO);
    return result;
}

- (NSURL *)URLForKey:(NSString *)defaultName {
    NSURL *result = nil;
    do {
        if (!defaultName) {
            break;
        }
        id tmp = [self objectForKey:defaultName];
        if (![tmp isKindOfClass:[NSURL class]]) {
            break;
        }
        result = tmp;
    } while (NO);
    return result;
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName {
    do {
        if (!defaultName) {
            break;
        }
        NSNumber *num = [NSNumber numberWithInteger:value];
        [self setObject:num forKey:defaultName];
    } while (NO);
}

- (void)setFloat:(float)value forKey:(NSString *)defaultName {
    do {
        if (!defaultName) {
            break;
        }
        NSNumber *num = [NSNumber numberWithFloat:value];
        [self setObject:num forKey:defaultName];
    } while (NO);
}

- (void)setDouble:(double)value forKey:(NSString *)defaultName {
    do {
        if (!defaultName) {
            break;
        }
        NSNumber *num = [NSNumber numberWithDouble:value];
        [self setObject:num forKey:defaultName];
    } while (NO);
}

- (void)setBool:(BOOL)value forKey:(NSString *)defaultName {
    do {
        if (!defaultName) {
            break;
        }
        NSNumber *num = [NSNumber numberWithBool:value];
        [self setObject:num forKey:defaultName];
    } while (NO);
}

@end
