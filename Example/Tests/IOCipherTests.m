//
//  IOCipherTests.m
//  IOCipher
//
//  Created by Christopher Ballinger on 1/20/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "IOCipher.h"

@interface IOCipherTests : XCTestCase
@property (nonatomic, strong) IOCipher *ioCipher;
@end

@implementation IOCipherTests

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSString*) dbPath {
    NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"test.sqlite"];
    return path;
}

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSString *path = [self dbPath];
    self.ioCipher = [[IOCipher alloc] initWithPath:path password:@"test"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.ioCipher = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self dbPath] error:nil];
}

- (void)testCreateFile {
    NSString *filePath = @"file.txt";
    NSError *error = nil;
    BOOL success = [self.ioCipher fileExistsAtPath:filePath isDirectory:NULL];
    XCTAssertFalse(success);
    success = [self.ioCipher createFileAtPath:filePath error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    success = [self.ioCipher createFileAtPath:filePath error:&error];
    BOOL isDirectory = YES;
    success = [self.ioCipher fileExistsAtPath:filePath isDirectory:&isDirectory];
    XCTAssertFalse(isDirectory);
    XCTAssertTrue(success, @"error: %@", error);
}

- (void)testCreateFolder {
    NSString *folder = @"folder";
    NSError *error = nil;
    BOOL success = [self.ioCipher createFolderAtPath:folder error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    BOOL isDirectory = NO;
    success = [self.ioCipher fileExistsAtPath:folder isDirectory:&isDirectory];
    XCTAssertTrue(isDirectory);
    XCTAssertTrue(success);
}

- (void)testRemoveFilesAndFolders {
    NSString *folder = @"/folder";
    NSString *file = @"file.txt";
    
    NSString *path = [folder stringByAppendingPathComponent:file];
    NSError *error = nil;
    BOOL success = [self.ioCipher createFolderAtPath:folder error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    success = [self.ioCipher createFileAtPath:path error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    success = [self.ioCipher removeItemAtPath:path error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    success = [self.ioCipher fileExistsAtPath:path isDirectory:NULL];
    XCTAssertFalse(success);
    success = [self.ioCipher removeItemAtPath:folder error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    success = [self.ioCipher fileExistsAtPath:path isDirectory:NULL];
    XCTAssertFalse(success);
}

- (void) testReadWriteData {
    NSString *filePath = @"file.txt";
    NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    BOOL success = [self.ioCipher createFileAtPath:filePath error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    NSUInteger bytesWritten = [self.ioCipher writeDataToFileAtPath:filePath data:fileData offset:0 error:&error];
    XCTAssert(bytesWritten == fileData.length, @"error: %@", error);
    NSData *readData = [self.ioCipher readDataFromFileAtPath:filePath length:fileData.length offset:0 error:&error];
    XCTAssertNotNil(readData, @"error: %@", error);
    XCTAssertEqualObjects(fileData, readData);
}


@end
