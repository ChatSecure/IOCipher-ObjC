//
//  ViewController.m
//  IOCipherServer
//
//  Created by Christopher Ballinger on 1/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "ViewController.h"
#import "GCDWebServer.h"
#import "IOCipher.h"
#import "SQLVirtualFile.h"
#import "GCDWebServerVirtualFileResponse.h"
#import <MediaPlayer/MPMoviePlayerViewController.h>

static NSString * const CellIdentifier = @"CellIdentifier";

@interface ViewController () <GCDWebServerDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) IOCipher *iocipher;
@property (nonatomic, strong) GCDWebServer *server;
@property (nonatomic, strong) NSMutableArray *virtualFiles;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupServer];
    [self setupIOCipher];
    self.virtualFiles = [NSMutableArray array];
    
    [self setupTableView];

    
    NSArray *files = [[NSBundle mainBundle] pathsForResourcesOfType:nil inDirectory:@"samples"];
    [files enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL *stop) {
        [self addLocalFileToEncryptedStore:filePath];
    }];
    [self.tableView reloadData];
}

- (void) setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
    [self.view addSubview:self.tableView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.tableView.frame = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
}


- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void) setupIOCipher {
    NSString *dbDirectory = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"IOCipher"];
    NSString *dbPath = [dbDirectory stringByAppendingPathComponent:@"vfs.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:dbDirectory isDirectory:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:dbDirectory error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:dbDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    self.iocipher = [[IOCipher alloc] initWithPath:dbPath password:@"test"];
}

- (void) addLocalFileToEncryptedStore:(NSString*)localFilePath {
    NSString *fileName = [localFilePath lastPathComponent];
    SQLVirtualFile *virtualFile = [[SQLVirtualFile alloc] initWithFileName:fileName];
    virtualFile.portNumber = self.server.port;
    NSError *error = nil;

    if (![self.iocipher fileExistsAtPath:virtualFile.uuid isDirectory:NULL]) {
        [self.iocipher createFolderAtPath:virtualFile.uuid error:&error];
        if (error) {
            NSLog(@"Error creating folder: %@", error);
            return;
        }
    }
    
    NSData *fileData = [NSData dataWithContentsOfFile:localFilePath];
    [self.iocipher writeDataToFileAtPath:virtualFile.virtualPath data:fileData offset:0 error:&error];
    if (error) {
        NSLog(@"Error writing file data");
        return;
    }
    
    IOCipher *iocipher = self.iocipher;
    [self.server addHandlerForMethod:@"GET" path:virtualFile.virtualPath requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        NSRange range = request.byteRange;
        
        NSLog(@"GET: (%d,%d) %@ %@", (int)range.location, (int)range.length, request.URL, request.headers);
        GCDWebServerResponse* response = [GCDWebServerVirtualFileResponse responseWithFile:virtualFile.virtualPath byteRange:request.byteRange isAttachment:NO ioCipher:iocipher];
        [response setValue:@"bytes" forAdditionalHeader:@"Accept-Ranges"];
        return response;
    }];
    
    [self.virtualFiles addObject:virtualFile];
}

- (void) setupServer {
    self.server = [[GCDWebServer alloc] init];
    self.server.delegate = self;
    NSError *error = nil;
    [self.server startWithOptions:nil error:&error];
    if (error) {
        NSLog(@"Error starting server: %@", error);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (SQLVirtualFile *) virtualFileAtIndexPath:(NSIndexPath*)indexPath {
    return [self.virtualFiles objectAtIndex:indexPath.row];
}

- (void) playFileWithURL:(NSURL*)url {
    NSParameterAssert(url != nil);
    MPMoviePlayerViewController *movie = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
    [self presentMoviePlayerViewControllerAnimated:movie];
}

#pragma mark UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SQLVirtualFile *file = [self virtualFileAtIndexPath:indexPath];
    NSURL *url = file.url;
    NSLog(@"Playing file at URL: %@", url);
    [self playFileWithURL:url];
}

#pragma mark UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.virtualFiles.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    SQLVirtualFile *file = [self virtualFileAtIndexPath:indexPath];
    cell.textLabel.text = file.fileName;
    return cell;
}


@end
