//
//  IOCipher.h
//  Pods
//
//  Created by Christopher Ballinger on 1/20/15.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/** Due to limitations of libsqlfs you can only have one instance of this class */
@interface IOCipher : NSObject

@property (nonatomic, strong, readonly) NSString *path;

/** password should be UTF-8 and have non-zero length */
- (nullable instancetype) initWithPath:(NSString*)path password:(NSString*)password;

/** key should be 32-bytes and have non-zero length */
- (nullable instancetype) initWithPath:(NSString*)path key:(NSData*)key;

/**
 *  Changes the passwod of the current store. This method closes and reopones the store so no writes or reads can occur.
 *
 *
 *  @param newPassword the new password that will be used after the change
 *  @param oldPassword the old password that was used previously
 *
 *  @return Whether changing the password was successful
 */
- (BOOL)changePassword:(NSString *)newPassword oldPassword:(NSString *)oldPassword;

/**
 *  Changes the key of the current store. This method closes and reopones the store so no writes or reads can occur.
 *  Keys should be 32-bytes
 *
 *  @param newKey the new key that will be used after the change
 *  @param oldKey the old key that was used previously
 *
 *  @return Whether changing the key was successful
 */
- (BOOL)changeKey:(NSData *)newKey oldKey:(NSData *)oldKey;

/**
 * Databases created with SQLCipher 3.0 are not compatible with SQLCipher 4.0.
 * Setting this flag will set "PRAGMA cipher_compatibility = %i" on the current database.
 * This must be called after the database is keyed.
 *
 * For more information see https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_compatibility
 **/
- (BOOL)setCipherCompatibility:(NSInteger)version;

@end

@interface IOCipher (FileManagement)

/** Creates file at path */
- (BOOL) createFileAtPath:(NSString*)path error:(NSError**)error;

/** Creates folder at path */
- (BOOL) createFolderAtPath:(NSString*)path error:(NSError**)error;

/** Removes file or folder at path */
- (BOOL) removeItemAtPath:(NSString*)path error:(NSError**)error;

/** Checks if file exists at path */
- (BOOL) fileExistsAtPath:(NSString *)path
              isDirectory:(BOOL * _Nullable)isDirectory;

/**
 *  Returns NSDictionary of file attributes similar to NSFileManager
 *
 *  Supported keys:
 *    * NSFileSize (NSNumber)
 *    * NSFileModificationDate (NSDate)
 *
 *  @param path file path
 *
 *  @return file attribute keys or nil if error
 */
- (nullable NSDictionary<NSFileAttributeKey, id> *) fileAttributesAtPath:(NSString*)path
                                                                   error:(NSError**)error;

@end

@interface IOCipher (FileData)

/**
 *  Reads data from file at path.
 *
 *  @param path   file path
 *  @param error  error
 *
 *  @return Data read from file, or nil if there was an error.
 */

- (nullable NSData*) readDataFromFileAtPath:(NSString*)path
                                      error:(NSError**)error;

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
- (nullable NSData*) readDataFromFileAtPath:(NSString*)path
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
- (NSInteger) writeDataToFileAtPath:(NSString*)path
                               data:(NSData*)data
                             offset:(NSUInteger)offset
                              error:(NSError**)error;

/**
 *  Truncates file at path to new length.
 *
 *  @param path   file path
 *  @param length new file length in bytes
 *  @param error  error
 *
 *  @return success or failure
 */
- (BOOL) truncateFileAtPath:(NSString*)path
                     length:(NSUInteger)length
                      error:(NSError**)error;


/**
 *  Asynchronously copy file from file system to encrypted storage
 *
 *  @param fileSystemPath   file path of the normal file system
 *  @param encryptedPath    file path in encrypted store
 */
- (BOOL) copyItemAtFileSystemPath:(NSString *)fileSystemPath
                  toEncryptedPath:(NSString *)encryptedPath
                            error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
