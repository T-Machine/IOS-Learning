//
//  NetworkViewController.m
//  FileReader2
//
//  Created by 陈统盼 on 2019/3/30.
//  Copyright © 2019 TMachine. All rights reserved.
//

#import "NetworkViewController.h"
#import "AppDelegate.h"

@interface NetworkViewController ()

@property (weak, nonatomic) IBOutlet UIButton *GET_Button;
@property (weak, nonatomic) IBOutlet UIButton *POST_Buttom;
@property (weak, nonatomic) IBOutlet UITextView *textView1;
@property (weak, nonatomic) IBOutlet UITextField *inputText;
@property (weak, nonatomic) IBOutlet UIButton *Download_Button;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressNumber;
@property (weak, nonatomic) IBOutlet UIButton *Pause_Button;
@property (weak, nonatomic) IBOutlet UIButton *GoOn_Button;
@property (weak, nonatomic) NSURLSessionDownloadTask *downloadTask;

@end


@implementation NetworkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// get 网络访问
- (void) sendHTTPGet {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject
                                                                      delegate: self
                                                                 delegateQueue: [NSOperationQueue mainQueue]];
    
    NSString *urlString = [[NSString alloc] initWithFormat:@"http://v.juhe.cn/xhzd/query?key=4bf056d6ac33cc971ed0a7b6c4584b40&word=%@", [self.inputText text]];
    // 处理中文字符
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];

    NSURL * url = [NSURL URLWithString:urlString];
    
    /*NSURL * url = [NSURL URLWithString:@"http://apis.juhe.cn/mobile/get?phone=15989012290&key=c680acd03f819f94521843d18c872711"];*/
    
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithURL:url
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             if(error == nil) {
                                                                 //NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                                                                 //NSLog(@"Data = %@",text);
                                                                 [self changeTextView1: data];
                                                             }
                                                             
                                                         }];
    
    [dataTask resume];
}

- (void) sendHTTPPost {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *delegateFreeSession = [NSURLSession sessionWithConfiguration: defaultConfigObject
                                                                      delegate: self
                                                                 delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:@"http://v.juhe.cn/xhzd/query"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    // 处理中文字符
    NSString *word = [[self.inputText text] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    NSString *params = [[NSString alloc] initWithFormat:@"word=%@&dtype=&key=4bf056d6ac33cc971ed0a7b6c4584b40", word];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask * dataTask = [delegateFreeSession dataTaskWithRequest:urlRequest
                                                         completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                             NSLog(@"Response: %@ %@\n", response, error);
                                                             if(error == nil) {
                                                                 [self changeTextView1: data];
                                                             }
                                                             
                                                         }];
    
    [dataTask resume];
    
}

- (void) downloadFile {
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject
                                                                      delegate: self
                                                                 delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:18081/download/test.txt"];
    
    NSURLSessionDownloadTask *downloadTask =[ defaultSession downloadTaskWithURL:url];
    self.downloadTask = downloadTask;
    [downloadTask resume];
}

- (void)changeTextView1: (NSData *)data {
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    NSLog(@"%@\n", jsonDict);
    NSDictionary *result = [jsonDict objectForKey:@"result"];
    NSArray *jijie = [result objectForKey:@"jijie"];
    
    NSString *text = [jijie objectAtIndex:2];
    NSLog(@"%@",text);
    
    [self.textView1 setText:text];
}

// 写入数据到本地时调用的代理方法
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    // 显示下载完成时的文件路径
    NSLog(@"Location :%@\n", location);
    NSError *err = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 将文件移动到document中
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    // 设置文件名
    NSURL *docsDirURL = [NSURL fileURLWithPath:[docsDir stringByAppendingPathComponent:@"test.txt"]];
    [fileManager moveItemAtURL:location
                         toURL:docsDirURL
                         error: &err];
    
    if(err != nil) {
        NSLog(@"Failed to move file to : %@", docsDir);
    } else {
        NSLog(@"Finish download: %@", docsDirURL);
    }
}

// 下载数据的过程中调用的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = totalBytesWritten * 1.0 /totalBytesExpectedToWrite;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:progress animated:YES];
        [self.progressNumber setText:[[NSString alloc] initWithFormat:@"%ld%%", (NSInteger)(progress * 100)]];
    });
}



- (IBAction)GET:(id)sender {
    [self sendHTTPGet];
}

- (IBAction)POST:(id)sender {
    [self sendHTTPPost];
}

- (IBAction)DOWNLOAD:(id)sender {
    [self downloadFile];
}

- (IBAction)DOWNLOAD_PAUSE:(id)sender {
    [self.downloadTask suspend];
}

- (IBAction)DOWNLOAD_GO_ON:(id)sender {
    [self.downloadTask resume];
}

@end
