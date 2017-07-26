/*
 Copyright (c) 2012-2014, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if !__has_feature(objc_arc)
#error GCDWebServer requires ARC
#endif

#import <sys/stat.h>

#import "GCDWebServerFunctions.h"
#import "GCDWebServerHTTPStatusCodes.h"
#import "GCDWebServerVirtualFileResponse.h"

#define kFileReadBufferSize (32 * 1024)

static inline BOOL GCDWebServerIsValidByteRange(NSRange range) {
    return ((range.location != NSUIntegerMax) || (range.length > 0));
}

static inline NSError* GCDWebServerMakePosixError(int code) {
    return [NSError errorWithDomain:NSPOSIXErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:strerror(code)]}];
}

@interface GCDWebServerVirtualFileResponse () {
@private
    NSString* _path;
    NSUInteger _offset;
    NSUInteger _size;
}
@end

@implementation GCDWebServerVirtualFileResponse

+ (instancetype)responseWithFile:(NSString*)path ioCipher:(IOCipher*)ioCipher {
    return [[[self class] alloc] initWithFile:path ioCipher:ioCipher];
}

+ (instancetype)responseWithFile:(NSString*)path isAttachment:(BOOL)attachment ioCipher:(IOCipher*)ioCipher {
    return [[[self class] alloc] initWithFile:path isAttachment:attachment ioCipher:ioCipher];
}

+ (instancetype)responseWithFile:(NSString*)path byteRange:(NSRange)range ioCipher:(IOCipher*)ioCipher {
    return [[[self class] alloc] initWithFile:path byteRange:range ioCipher:ioCipher];
}

+ (instancetype)responseWithFile:(NSString*)path byteRange:(NSRange)range isAttachment:(BOOL)attachment ioCipher:(IOCipher*)ioCipher {
    return [[[self class] alloc] initWithFile:path byteRange:range isAttachment:attachment ioCipher:ioCipher];
}

- (instancetype)initWithFile:(NSString*)path ioCipher:(IOCipher*)ioCipher {
    return [self initWithFile:path byteRange:NSMakeRange(NSUIntegerMax, 0) isAttachment:NO ioCipher:ioCipher];
}

- (instancetype)initWithFile:(NSString*)path isAttachment:(BOOL)attachment ioCipher:(IOCipher*)ioCipher {
    return [self initWithFile:path byteRange:NSMakeRange(NSUIntegerMax, 0) isAttachment:attachment ioCipher:ioCipher];
}

- (instancetype)initWithFile:(NSString*)path byteRange:(NSRange)range ioCipher:(IOCipher*)ioCipher {
    return [self initWithFile:path byteRange:range isAttachment:NO ioCipher:ioCipher];
}

- (instancetype)initWithFile:(NSString*)path byteRange:(NSRange)range isAttachment:(BOOL)attachment ioCipher:(IOCipher*)ioCipher {
    _ioCipher = ioCipher;
    NSError *error = nil;
    NSDictionary *fileAttributes = [self.ioCipher fileAttributesAtPath:path error:&error];
    NSUInteger fileSize = [fileAttributes[NSFileSize] unsignedIntegerValue];
    
    BOOL hasByteRange = GCDWebServerIsValidByteRange(range);
    if (hasByteRange) {
        if (range.location != NSUIntegerMax) {
            range.location = MIN(range.location, fileSize);
            range.length = MIN(range.length, fileSize - range.location);
        } else {
            range.length = MIN(range.length, fileSize);
            range.location = fileSize - range.length;
        }
        if (range.length == 0) {
            return nil;  // TODO: Return 416 status code and "Content-Range: bytes */{file length}" header
        }
    } else {
        range.location = 0;
        range.length = fileSize;
    }
    
    if ((self = [super init])) {
        _path = [path copy];
        _offset = range.location;
        _size = range.length;
        if (hasByteRange) {
            [self setStatusCode:kGCDWebServerHTTPStatusCode_PartialContent];
            [self setValue:[NSString stringWithFormat:@"bytes %lu-%lu/%lu", (unsigned long)_offset, (unsigned long)(_offset + _size - 1), (unsigned long)fileSize] forAdditionalHeader:@"Content-Range"];
        }
        
        if (attachment) {
            NSString* fileName = [path lastPathComponent];
            NSData* data = [[fileName stringByReplacingOccurrencesOfString:@"\"" withString:@""] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
            NSString* lossyFileName = data ? [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] : nil;
            if (lossyFileName) {
                NSString* value = [NSString stringWithFormat:@"attachment; filename=\"%@\"; filename*=UTF-8''%@", lossyFileName, GCDWebServerEscapeURLString(fileName)];
                [self setValue:value forAdditionalHeader:@"Content-Disposition"];
            }
        }
        
        self.contentType = GCDWebServerGetMimeTypeForExtension([_path pathExtension], nil);
        self.contentLength = _size;
        self.lastModifiedDate = fileAttributes[NSFileModificationDate];
        //self.eTag = [NSString stringWithFormat:@"%llu/%li/%li", info.st_ino, info.st_mtimespec.tv_sec, info.st_mtimespec.tv_nsec];
    }
    return self;
}

- (BOOL)open:(NSError**)error {
    BOOL fileExists = [self.ioCipher fileExistsAtPath:_path isDirectory:NULL];
    if (!fileExists) {
        if (error) {
            *error = GCDWebServerMakePosixError(ENOENT);
        }
        return NO;
    }
    return YES;
}

- (NSData*)readData:(NSError**)error {
    size_t length = MIN((NSUInteger)kFileReadBufferSize, _size);
    if (length == 0) {
        return [NSData data];
    }
    NSData *data = [self.ioCipher readDataFromFileAtPath:_path length:length offset:_offset error:error];
    if (!data) {
        if (error) {
            *error = GCDWebServerMakePosixError(EIO);
        }
        return nil;
    }
    if (data.length > 0) {
        _size -= data.length;
        _offset += data.length;
    }
    return data;
}

- (void)close {
    // sqlfs has no "close" operation
}

- (NSString*)description {
    NSMutableString* description = [NSMutableString stringWithString:[super description]];
    [description appendFormat:@"\n\n{%@}", _path];
    return description;
}

@end
