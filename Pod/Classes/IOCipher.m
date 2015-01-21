//
//  IOCipher.m
//  Pods
//
//  Created by Christopher Ballinger on 1/20/15.
//
//

#import "IOCipher.h"
#import "sqlfs.h"

@interface IOCipher()
@property (nonatomic, readonly) sqlfs_t *sqlfs;
@end

@implementation IOCipher

- (void) dealloc {
    if (_sqlfs) {
        sqlfs_close(_sqlfs);
        _sqlfs = NULL;
    }
}

/** password should be UTF-8 */
- (instancetype) initWithPath:(NSString*)path password:(NSString*)password {
    NSParameterAssert(path != nil);
    NSAssert(password.length > 0, @"password should have a non-zero length!");
    if (password.length == 0) {
        return nil;
    }
    if (self = [super init]) {
        sqlfs_open_password([path UTF8String], [password UTF8String], &_sqlfs);
    }
    return self;
}

/** key should be 32-bytes */
- (instancetype) initWithPath:(NSString*)path key:(NSData*)key {
    NSParameterAssert(path != nil);
    NSAssert(key.length == 32, @"key must be 32 bytes");
    if (key.length != 32) {
        return nil;
    }
    if (self = [super init]) {
        sqlfs_open_key([path UTF8String], [key bytes], key.length, &_sqlfs);
    }
    return self;
}

/** Creates file at path */
- (BOOL) createFileAtPath:(NSString*)path error:(NSError**)error {
    struct fuse_file_info ffi;
    ffi.direct_io = 0;
    int result = sqlfs_proc_create(_sqlfs, [path UTF8String], 0, &ffi);
    if (result == SQLITE_OK) {
        return YES;
    } else if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:result userInfo:nil];
    }
    return NO;
}

/** Creates folder at path */
- (BOOL) createFolderAtPath:(NSString*)path error:(NSError**)error {
    NSParameterAssert(path != nil);
    if (!path) {
        return NO;
    }
    int result = sqlfs_proc_mkdir(_sqlfs, [path UTF8String], 0);
    if (result == SQLITE_OK) {
        return YES;
    } else if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:result userInfo:nil];
    }
    return NO;
}

/** Removes file or folder at path */
- (BOOL) removeItemAtPath:(NSString*)path error:(NSError**)error {
    NSParameterAssert(path != nil);
    if (!path) {
        return NO;
    }
    const char * cPath = [path UTF8String];
    int result = -1;
    if (sqlfs_is_dir(_sqlfs, cPath)) {
        result = sqlfs_proc_rmdir(_sqlfs, cPath);
    } else {
        result = sqlfs_proc_unlink(_sqlfs, cPath);
    }
    if (result == SQLITE_OK) {
        return YES;
    } else if (error) {
        *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:result userInfo:nil];
    }
    return NO;
}


- (BOOL)fileExistsAtPath:(NSString *)path
             isDirectory:(BOOL *)isDirectory {
    NSParameterAssert(path != nil);
    if (!path) {
        return NO;
    }
    const char * cPath = [path UTF8String];
    if (isDirectory) {
        *isDirectory = sqlfs_is_dir(_sqlfs, cPath);
    }
    int result = sqlfs_proc_access(_sqlfs, cPath, 0);
    if (result == SQLITE_OK) {
        return YES;
    }
    return NO;
}

/**
 *  Reads data from file at path.
 *
 *  @param path   file path
 *  @param length length of data to read in bytes
 *  @param offset byte offset in file
 *  @param error  error
 *
 *  @return Data read from file, or nil if there was an error. May be less than length.
 */
- (NSData*) readDataFromFileAtPath:(NSString*)path
                            length:(NSUInteger)length
                            offset:(NSUInteger)offset
                             error:(NSError**)error {
    NSParameterAssert(path != nil);
    if (!path) {
        return nil;
    }
    struct fuse_file_info ffi;
    const char * cPath = [path UTF8String];
    uint8_t *bytes = malloc(sizeof(uint8_t) * length);
    if (!bytes) {
        return nil;
    }
    int bytesRead = sqlfs_proc_read(_sqlfs,
                                  cPath,
                                  (char*)bytes,
                                  length,
                                  offset,
                                  &ffi);
    NSData *data = [NSData dataWithBytesNoCopy:bytes length:bytesRead freeWhenDone:YES];
    if (bytesRead < 0) {
        if (bytesRead != -EIO) { // sqlfs_proc_open returns EIO on end-of-file
            if (error) {
                *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:bytesRead userInfo:nil];
            }
        }
        return nil;
    } else {
        return data;
    }
    return nil;
}

/**
 *  Writes data to file at path at offset.
 *
 *  @param path   file path
 *  @param data   data to write
 *  @param offset byte offset in file
 *  @param error  error
 *
 *  @return number of bytes written
 */
- (NSUInteger) writeDataToFileAtPath:(NSString*)path
                                data:(NSData*)data
                              offset:(NSUInteger)offset
                               error:(NSError**)error {
    NSParameterAssert(path != nil);
    NSParameterAssert(data != nil);
    if (!path || !data) {
        return NO;
    }
    struct fuse_file_info ffi;
    const char * cPath = [path UTF8String];
    int bytesWritten = sqlfs_proc_write(_sqlfs,
                                  cPath,
                                  data.bytes,
                                  data.length,
                                  offset,
                                  &ffi);
    if (bytesWritten < 0) {
        if (error) {
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:bytesWritten userInfo:nil];
        }
        return -1;
    } else {
        return bytesWritten;
    }
}


@end
