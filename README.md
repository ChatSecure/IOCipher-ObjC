# [IOCipher-ObjC](https://github.com/ChatSecure/IOCipher-ObjC)

[![Build Status](https://travis-ci.org/ChatSecure/IOCipher-ObjC.svg?branch=master)](https://travis-ci.org/ChatSecure/IOCipher-ObjC)
[![Version](https://img.shields.io/cocoapods/v/IOCipher.svg?style=flat)](http://cocoadocs.org/docsets/IOCipher)
[![License](https://img.shields.io/cocoapods/l/IOCipher.svg?style=flat)](http://cocoadocs.org/docsets/IOCipher)
[![Platform](https://img.shields.io/cocoapods/p/IOCipher.svg?style=flat)](http://cocoadocs.org/docsets/IOCipher)

IOCipher allows you to create an encrypted virtual file store within a SQLite/SQLCipher database. The Obj-C version mirrors the NSFileManager API as much as possible for familiarity and easy of use.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

The `IOCipher` class contains all of the required functionality for working with encrypted files. The `GCDWebServerVirtualFileResponse` class is for usage with an embedded HTTP server for decypting files on the fly to better integrate with the stock iOS media playback APIs.

## Installation

IOCipher is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod 'IOCipher'
    
You can also use the `'IOCipher/GCDWebServer'` subspec if you want to support decryption on-the-fly via an embedded HTTP server ([GCDWebServer](https://github.com/swisspol/GCDWebServer)). This allows you to support playback in the default iOS media player by decrypting everything as it's requested. Details on how to implement this are available in the Example project.

## Author

[Chris Ballinger](https://github.com/chrisballinger), chris@chatsecure.org

## License

IOCipher is available under the LGPLv2.1+ license. See the LICENSE file for more info.