//
//  DCJSONUserDefault.m
//  BalanceWheel
//
//  Created by Derek Chen on 8/6/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import "DCJSONUserDefault.h"
#import "DCJSONFile.h"

@interface DCJSONUserDefault () {
}

@property (strong, nonatomic) NSMutableDictionary *jsonFileDict;

@end

@implementation DCJSONUserDefault

@synthesize jsonFileDict = _jsonFileDict;

DEFINE_SINGLETON_FOR_CLASS(DCJSONUserDefault)

- (id)init {
    self = [super init];
    if (self) {
        self.jsonFileDict = [[NSMutableDictionary dictionary] threadSafe_init];
    }
    return self;
}

- (void)dealloc {
    do {
        [self synchronize];
        self.jsonFileDict = nil;
    } while (NO);
}

- (NSUInteger)getManagedJSONFileCount {
    NSUInteger result = 0;
    do {
        if (!self.jsonFileDict) {
            break;
        }
        result = [self.jsonFileDict threadSafe_count];
    } while (NO);
    return result;
}

- (NSArray *)getAllManagedJSONFilePaths {
    NSArray *result = nil;
    do {
        if (!self.jsonFileDict) {
            break;
        }
        result = [self.jsonFileDict threadSafe_allKeys];
    } while (NO);
    return result;
}

- (BOOL)setJSONFile:(DCJSONFile *)file byPath:(NSString *)path {
    BOOL result = NO;
    do {
        if (!file || !path || !self.jsonFileDict) {
            break;
        }
        [self.jsonFileDict threadSafe_setObject:file forKey:path];
        result = YES;
    } while (NO);
    return result;
}

- (DCJSONFile *)getJSONFileByPath:(NSString *)path {
    DCJSONFile *result = nil;
    do {
        if (!path || !self.jsonFileDict) {
            break;
        }
        result = [self.jsonFileDict threadSafe_objectForKey:path];
    } while (NO);
    return result;
}

- (BOOL)synchronize {
    BOOL result = NO;
    do {
        if (!self.jsonFileDict) {
            break;
        }
        NSArray *allValues = [self.jsonFileDict threadSafe_allValues];
        BOOL allSucc = YES;
        for (DCJSONFile *file in allValues) {
            if (![file synchronize]) {
                allSucc = NO;
                break;
            }
        }
        if (!allSucc) {
            break;
        }
        result = YES;
    } while (NO);
    return result;
}


@end
