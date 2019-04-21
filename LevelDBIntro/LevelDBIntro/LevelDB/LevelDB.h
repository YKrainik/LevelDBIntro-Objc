//
//  LevelDB.h
//  LevelDBIntro
//
//  Created by AP Yury Krainik on 4/13/19.
//  Copyright © 2019 AP Yury Krainik. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <leveldb/db.h>

using namespace leveldb;

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^KeyBlock)(NSString *key);
typedef BOOL (^KeyValueBlock)(NSString *key, id value);

@interface LevelDB: NSObject {
	DB *db;
	ReadOptions readOptions;
	WriteOptions writeOptions;
}

@property (nonatomic, copy) NSString *path;

+ (id)libraryPath;
+ (LevelDB *)databaseInLibraryWithName:(NSString *)name;

- (id)initWithPath:(NSString *)path;
- (void)putObject:(id)value forKey:(NSString *)key;
- (id)getObject:(NSString *)key;

- (void)iterateKeys:(KeyBlock)block;
- (void)iterate:(KeyValueBlock)block;
- (void)reverseIterate:(KeyValueBlock)block;

- (void)iterateSnapshot:(KeyValueBlock)block;

- (NSArray *)allKeys;

- (void)deleteObject:(NSString *)key;
- (void)clear;
- (void)deleteDatabase;

@end

NS_ASSUME_NONNULL_END
