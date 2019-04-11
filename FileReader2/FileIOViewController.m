//
//  FileIOViewController.m
//  FileReader2
//
//  Created by 陈统盼 on 2019/4/11.
//  Copyright © 2019 TMachine. All rights reserved.
//

#import "FileIOViewController.h"
#import "AppDelegate.h"

@interface FileIOViewController()

@property (weak, nonatomic) IBOutlet UITextField *textWrite;
@property (weak, nonatomic) IBOutlet UITextView *textRead;
@property NSString *filePath;


@end


@implementation FileIOViewController

- (void)viewDidLoad {
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSLog(@"path: %@", document);
    self.filePath = [document stringByAppendingPathComponent:@"Hello.txt"];
    NSLog(@"path: %@", self.filePath);
}

- (IBAction)writeFile:(id)sender {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSLog(@"path: %@", self.filePath);
    if (![fileManager fileExistsAtPath:self.filePath]) {
        NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
        [fileManager createFileAtPath:self.filePath contents:data attributes:nil];
    }
    
    NSString *contents = [self.textWrite text];
    [contents writeToFile:self.filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (IBAction)readFile:(id)sender {
    NSString *content = [NSString stringWithContentsOfFile:self.filePath encoding:NSUTF8StringEncoding error:nil];
    [self.textRead setText:content];
}

@end
