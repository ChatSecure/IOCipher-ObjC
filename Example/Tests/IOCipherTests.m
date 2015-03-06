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

NSString *const IOCipherTestPassword = @"test";

@implementation IOCipherTests

- (NSString *) applicationDocumentsDirectory
{
    return [[NSFileManager defaultManager] currentDirectoryPath];;
}

- (NSString*) dbPath {
    NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"test.sqlite"];
    return path;
}

- (NSData *)dataOfLength:(NSUInteger)length
{
    NSMutableData* data = [NSMutableData dataWithCapacity:length];
    for (NSUInteger index = 0; index < length/4; index++) {
        u_int32_t randomBits = arc4random();
        [data appendBytes:(void*)&randomBits length:4];
    }
    return data;
}

- (void)removeAllFilesInDirectory:(NSString *)directory
{
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directory];
    NSString *file = nil;
    while (file = [enumerator nextObject]) {
        [[NSFileManager defaultManager] removeItemAtPath:[directory stringByAppendingPathComponent:file] error:nil];
    }
}

- (void)setUp {
    [super setUp];
    
    NSString *path = [self dbPath];
    [self removeAllFilesInDirectory:[path stringByDeletingLastPathComponent]];
    BOOL isDirectory = NO;
    NSString *directory = [path stringByDeletingLastPathComponent];
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory];
    XCTAssertTrue(exists,@"Directory does not exist: %@",directory);
    XCTAssertTrue(isDirectory,@"Directory is not directory");
    
    self.ioCipher = [[IOCipher alloc] initWithPath:path password:IOCipherTestPassword];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    self.ioCipher = nil;
    [self removeAllFilesInDirectory:[[self dbPath] stringByDeletingLastPathComponent]];
}

- (void)testWriteToDocuments
{
    NSString *path = [[[self dbPath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"test.txt"];
    NSData *data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    
    [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    NSData *newData = [[NSFileManager defaultManager] contentsAtPath:path];
    XCTAssertTrue([data isEqualToData:newData]);
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

- (void) testFileAttributes {
    NSString *filePath = @"file.txt";
    NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    BOOL success = [self.ioCipher createFileAtPath:filePath error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    NSUInteger bytesWritten = [self.ioCipher writeDataToFileAtPath:filePath data:fileData offset:0 error:&error];
    XCTAssert(bytesWritten == fileData.length, @"error: %@", error);
    NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:filePath error:&error];
    XCTAssertNotNil(fileAttributes, @"error: %@", error);
    NSNumber *fileSize = fileAttributes[NSFileSize];
    NSDate *dateModified = fileAttributes[NSFileModificationDate];
    XCTAssert(fileSize.unsignedIntegerValue == fileData.length, @"File size doesn't match");
    XCTAssertNotNil(dateModified);
}

- (void) testTruncateFile {
    NSString *filePath = @"file.txt";
    NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    BOOL success = [self.ioCipher createFileAtPath:filePath error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    NSUInteger bytesWritten = [self.ioCipher writeDataToFileAtPath:filePath data:fileData offset:0 error:&error];
    XCTAssert(bytesWritten == fileData.length, @"error: %@", error);
    
    NSUInteger newFileLength = 3;
    success = [self.ioCipher truncateFileAtPath:filePath length:newFileLength error:&error];
    
    XCTAssertTrue(success, @"error: %@", error);
    
    NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:filePath error:&error];
    XCTAssertNotNil(fileAttributes, @"error: %@", error);
    NSNumber *fileSize = fileAttributes[NSFileSize];
    XCTAssert(fileSize.unsignedIntegerValue == newFileLength, @"New file size doesn't match");
}

- (void) testFileSystemCopy {
    
    NSData *data = [self dataOfLength:20000000];
    
    XCTAssert([data length] > 0);
    
    NSString *path = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"random"];
    BOOL createdFile = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    
    XCTAssertTrue(createdFile, @"Unable to create file in documents path");
    
    NSString *encryptedPath = @"/test/random";
    
    NSError *error = nil;
    BOOL succes = [self.ioCipher copyItemAtFileSystemPath:path toEncryptedPath:encryptedPath error:&error];
    
    XCTAssertNil(error,@"Error copying file");
    XCTAssertTrue(succes, @"Error unable to copy");
    
    NSData *originalData = [[NSFileManager defaultManager] contentsAtPath:path];
    NSDictionary *attributes = [self.ioCipher fileAttributesAtPath:encryptedPath error:&error];
    XCTAssertNil(error,@"Error getting file attributes");
    XCTAssertGreaterThan([[attributes allKeys] count], 0, @"No attributes retrieved");
    NSNumber *fileSize = attributes[NSFileSize];
    NSData *encryptedData = [self.ioCipher readDataFromFileAtPath:encryptedPath length:fileSize.unsignedIntegerValue offset:0 error:&error];
    XCTAssertNil(error,@"Error getting encrypted data");
    XCTAssertNotNil(encryptedData,@"No encrypted file data");
    XCTAssertNotNil(originalData,@"No original file data");
    
    XCTAssertTrue([originalData isEqualToData:encryptedData], @"Data not the same");
}
- (void) testReadFile {
    NSString *filePath = @"file.txt";
    NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    BOOL success = [self.ioCipher createFileAtPath:filePath error:&error];
    XCTAssertTrue(success, @"error: %@", error);
    NSUInteger bytesWritten = [self.ioCipher writeDataToFileAtPath:filePath data:fileData offset:0 error:&error];
    XCTAssertNil(error, @"Error writing file");
    XCTAssert(bytesWritten == fileData.length, @"error: %@", error);
    
    NSError *readError = nil;
    NSData *readData = [self.ioCipher readDataFromFileAtPath:filePath error:&readError];
    XCTAssertNil(readError, @"Error reading Data");
    XCTAssertTrue([readData isEqualToData:fileData], @"File data is not equal");
}

- (void)testChangePassword
{
    NSString *filePath = @"file.txt";
    NSData *fileData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    [self.ioCipher createFileAtPath:filePath error:nil];
    [self.ioCipher writeDataToFileAtPath:filePath data:fileData offset:0 error:nil];
    BOOL changePasswordResult = [self.ioCipher changePassword:@"newPassword" oldPassword:IOCipherTestPassword];
    XCTAssertTrue(changePasswordResult,@"Unable to change password");
    NSData *data = [self.ioCipher readDataFromFileAtPath:filePath error:nil];
    XCTAssertNotNil(data, @"No data found");
    XCTAssertTrue([data isEqualToData:fileData],@"Data is not equal");
}


@end
