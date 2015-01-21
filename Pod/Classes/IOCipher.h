//
//  IOCipher.h
//  Pods
//
//  Created by Christopher Ballinger on 1/20/15.
//
//

#import <Foundation/Foundation.h>

/** Due to limitations of libsqlfs you can only have one instance of this class */
@interface IOCipher : NSObject

/** password should be UTF-8 */
- (instancetype) initWithPath:(NSString*)path password:(NSString*)password;

/** key should be 32-bytes */
- (instancetype) initWithPath:(NSString*)path key:(NSData*)key;

@end

@interface IOCipher (Files)

/** Creates file at path */
- (BOOL) createFileAtPath:(NSString*)path error:(NSError**)error;

/** Creates folder at path */
- (BOOL) createFolderAtPath:(NSString*)path error:(NSError**)error;

/** Removes file or folder at path */
- (BOOL) removeItemAtPath:(NSString*)path error:(NSError**)error;

/** Checks if file exists at path */
- (BOOL)fileExistsAtPath:(NSString *)path
             isDirectory:(BOOL *)isDirectory;

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
                             error:(NSError**)error;

/**
 *  Writes data to file at path at offset.
 *
 *  @param path   file path
 *  @param data   data to write
 *  @param offset byte offset in file
 *  @param error  error
 *
 *  @return number of bytes written, or -1 if error
 */
- (NSUInteger) writeDataToFileAtPath:(NSString*)path
                                data:(NSData*)data
                              offset:(NSUInteger)offset
                               error:(NSError**)error;

@end