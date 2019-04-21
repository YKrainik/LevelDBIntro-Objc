//
//  ViewController.m
//  LevelDBIntro
//
//  Created by AP Yury Krainik on 4/13/19.
//  Copyright © 2019 AP Yury Krainik. All rights reserved.
//

#import "ViewController.h"
#import "LevelDB.h"

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	LevelDB *db = [LevelDB databaseInLibraryWithName: @"Test"];

	[db clear];

	[db putObject: @"Hello" forKey: @"string"];
	[db putObject: [NSDate new] forKey: @"date"];
	[db putObject: @[@"1", @"2", @"3"] forKey: @"array"];
	[db putObject: @{@"a": @"valueA", @"b": @"valueB"} forKey: @"key4"];

	NSString *res = [db getObject: @"date"];
	NSLog(@"Date: %@", res);

	NSLog(@"----------- Key iteration -----------");
	[db iterateKeys:^BOOL(NSString * _Nonnull key) {
		NSLog(@"Key: %@", key);
		return true;
	}];

	NSLog(@"----------- Key/Value iteration -----------");
	[db iterate:^BOOL(NSString * _Nonnull key, id  _Nonnull value) {
		NSLog(@"%@: %@", key, value);
		return true;
	}];

	NSLog(@"----------- Key/Value reverse iteration -----------");
	[db reverseIterate:^BOOL(NSString * _Nonnull key, id  _Nonnull value) {
		NSLog(@"%@: %@", key, value);
		return true;
	}];

	NSLog(@"----------- Key/Value iteration using snapshot -----------");
	[db iterateSnapshot:^BOOL(NSString * _Nonnull key, id  _Nonnull value) {
		NSLog(@"%@: %@", key, value);
		return true;
	}];

	[db deleteDatabase];
}

@end
