//
//  LevelDB.m
//  LevelDBIntro
//
//  Created by AP Yury Krainik on 4/13/19.
//  Copyright © 2019 AP Yury Krainik. All rights reserved.
//

#import "LevelDB.h"
#import <leveldb/db.h>

#define SliceFromString(_string_) (Slice((char *)[_string_ UTF8String], [_string_ lengthOfBytesUsingEncoding:NSUTF8StringEncoding]))

#define StringFromSlice(_slice_) ([[NSString alloc] initWithBytes:_slice_.data() length:_slice_.size() encoding:NSUTF8StringEncoding])

static Slice SliceFromObject(id object) {
	NSMutableData *d = [[NSMutableData alloc] init];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:d];
	[archiver encodeObject:object forKey:@"object"];
	[archiver finishEncoding];
	return Slice((const char *)[d bytes], (size_t)[d length]);
}

static id ObjectFromSlice(Slice v) {
	NSData *data = [NSData dataWithBytes:v.data() length:v.size()];
	NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	id object = [unarchiver decodeObjectForKey:@"object"];
	[unarchiver finishDecoding];
	return object;
}

@implementation LevelDB

+ (id)libraryPath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	return [paths objectAtIndex:0];
}

+ (LevelDB *)databaseInLibraryWithName:(NSString *)name {
	NSString *path = [[LevelDB libraryPath] stringByAppendingPathComponent:name];
	LevelDB *ldb = [[LevelDB alloc] initWithPath:path];
	return ldb;
}

- (id)initWithPath:(NSString *)path {
	self = [super init];

	if (self) {
		 _path = path;
		Options options;
		options.create_if_missing = true;
		Status status = leveldb::DB::Open(options, [_path UTF8String], &db);
		readOptions.fill_cache = false;
		writeOptions.sync = false;

		if (!status.ok()) {
			NSLog(@"Problem creating LevelDB database: %s", status.ToString().c_str());
		}
	}

	return self;
}

- (void)putObject:(id)value forKey:(NSString *)key {
	Slice k = SliceFromString(key);
	Slice v = SliceFromObject(value);
	Status status = db->Put(writeOptions, k, v);

	if (!status.ok()) {
		NSLog(@"Problem storing key/value pair in database: %s", status.ToString().c_str());
	}
}

- (id)getObject:(NSString *)key {
	std::string v_string;

	Slice k = SliceFromString(key);
	Status status = db->Get(readOptions, k, &v_string);

	if (!status.ok()) {
		if (!status.IsNotFound())
			NSLog(@"Problem retrieving value for key '%@' from database: %s", key, status.ToString().c_str());
		return nil;
	}

	return ObjectFromSlice(v_string);
}

- (void)iterateKeys:(KeyBlock)block {
	Iterator* iter = db->NewIterator(ReadOptions());
	for (iter->SeekToFirst(); iter->Valid(); iter->Next()) {
		Slice key = iter->key();
		NSString *k = StringFromSlice(key);
		if (!block(k)) {
			break;
		}
	}

	delete iter;
}

- (void)iterate:(KeyValueBlock)block {
	Iterator* iter = db->NewIterator(ReadOptions());
	for (iter->SeekToFirst(); iter->Valid(); iter->Next()) {
		Slice key = iter->key(), value = iter->value();
		NSString *k = StringFromSlice(key);
		id v = ObjectFromSlice(value);
		if (!block(k, v)) {
			break;
		}
	}

	delete iter;
}

- (void)iterateSnapshot:(KeyValueBlock)block {

	leveldb::ReadOptions options;
	options.snapshot = db->GetSnapshot();

	Iterator* iter = db->NewIterator(options);
	for (iter->SeekToFirst(); iter->Valid(); iter->Next()) {
		Slice key = iter->key(), value = iter->value();
		NSString *k = StringFromSlice(key);
		id v = ObjectFromSlice(value);
		if (!block(k, v)) {
			break;
		}
	}

	db->ReleaseSnapshot(options.snapshot);
	delete iter;
}

- (void)reverseIterate:(KeyValueBlock)block {
	Iterator* iter = db->NewIterator(ReadOptions());
	for (iter->SeekToLast(); iter->Valid(); iter->Prev()) {
		Slice key = iter->key(), value = iter->value();
		NSString *k = StringFromSlice(key);
		id v = ObjectFromSlice(value);
		if (!block(k, v)) {
			break;
		}
	}

	delete iter;
}

- (NSArray *)allKeys {
	NSMutableArray *keys = [[NSMutableArray alloc] init];
	//test iteration
	[self iterateKeys:^BOOL(NSString *key) {
		[keys addObject:key];
		return TRUE;
	}];
	return keys;
}

- (void)deleteObject:(NSString *)key {
	Slice k = SliceFromString(key);
	Status status = db->Delete(writeOptions, k);

	if (!status.ok()) {
		NSLog(@"Problem deleting key/value pair in database: %s", status.ToString().c_str());
	}
}

- (void)clear {
	NSArray *keys = [self allKeys];
	for (NSString *k in keys) {
		[self deleteObject:k];
	}
}

- (void)deleteDatabase {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error;
	[fileManager removeItemAtPath:_path error:&error];
}

@end
