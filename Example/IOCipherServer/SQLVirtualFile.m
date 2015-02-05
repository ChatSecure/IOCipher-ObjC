//
//  SQLVirtualFile.m
//  IOCipher
//
//  Created by Christopher Ballinger on 1/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "SQLVirtualFile.h"

@implementation SQLVirtualFile
@dynamic virtualPath;
@dynamic url;

- (instancetype) initWithFileName:(NSString*)fileName {
    if (self = [super init]) {
        _uuid = [[NSUUID UUID] UUIDString];
        _fileName = fileName;
        _portNumber = 80;
    }
    return self;
}

- (NSString*) virtualPath {
    return [NSString stringWithFormat:@"/%@/%@", self.uuid, self.fileName];
}

- (NSString*) description {
    NSString *description = [[super description] stringByAppendingFormat:@": %@", self.virtualPath];
    return description;
}

- (NSURL*) url {
    NSString *path = self.virtualPath;
    NSString *urlString = [NSString stringWithFormat:@"http://localhost:%d%@", self.portNumber, path];
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}

@end
