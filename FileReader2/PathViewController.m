//
//  PathViewController.m
//  FileReader2
//
//  Created by 陈统盼 on 2019/4/11.
//  Copyright © 2019 TMachine. All rights reserved.
//

#import "PathViewController.h"
#import "AppDelegate.h"

@interface PathViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textDocument;
@property (weak, nonatomic) IBOutlet UITextView *textCache;
@property (weak, nonatomic) IBOutlet UITextView *textLibrary;
@property (weak, nonatomic) IBOutlet UITextView *textTmp;
@property (weak, nonatomic) IBOutlet UITextView *textHome;

@end


@implementation PathViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *homeParh = NSHomeDirectory();
    [self.textHome setText:homeParh];
    
    // Document directory
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [documentPaths objectAtIndex:0];
    [self.textDocument setText:documentPath];
    
    // Cache directory
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [cachePaths objectAtIndex:0];
    [self.textCache setText:cachePath];
    
    // Library directory
    NSArray *libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryPath = [libraryPaths objectAtIndex:0];
    [self.textLibrary setText:libraryPath];
    
    // Tmp directory
    NSString *tmpPath = NSTemporaryDirectory();
    [self.textTmp setText:tmpPath];
    
}


@end
