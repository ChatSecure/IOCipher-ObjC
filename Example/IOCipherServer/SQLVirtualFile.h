//
//  SQLVirtualFile.h
//  IOCipher
//
//  Created by Christopher Ballinger on 1/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SQLVirtualFile : NSObject

/** dynamic accessor for @"/$uuid/$fileName" */
@property (nonatomic, strong, readonly) NSString *virtualPath;

/** file name, not neccessarily unique */
@property (nonatomic, strong, readonly) NSString *fileName;

/** unique UUID created for every file. used as unique directory */
@property (nonatomic, strong, readonly) NSString *uuid;

/** dynamic accessor for HTTP URL for use with GCDWebServerVirtualFileResponse */
@property (nonatomic, strong, readonly) NSURL *url;

/** port number of running HTTP server */
@property (nonatomic) uint16_t portNumber;

/** creates a unique directory / uuid for each file to prevent filename collisions */
- (instancetype) initWithFileName:(NSString*)fileName;

@end
