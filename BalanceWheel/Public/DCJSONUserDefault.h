//
//  DCJSONUserDefault.h
//  BalanceWheel
//
//  Created by Derek Chen on 8/6/14.
//  Copyright (c) 2014 Derek Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Tourbillon/DCTourbillon.h"

@class DCJSONFile;

@interface DCJSONUserDefault : NSObject {
}

DEFINE_SINGLETON_FOR_HEADER(DCJSONUserDefault)

- (NSUInteger)getManagedJSONFileCount;
- (NSArray *)getAllManagedJSONFilePaths;
- (BOOL)setJSONFile:(DCJSONFile *)file byPath:(NSString *)path;
- (DCJSONFile *)getJSONFileByPath:(NSString *)path;
- (BOOL)synchronize;

@end
