//
//  FileExploreViewController.m
//  FileReader2
//
//  Created by 陈统盼 on 2019/3/24.
//  Copyright © 2019 TMachine. All rights reserved.
//

#import "FileExploreViewController.h"
#import "FileDetialViewController.h"

@interface FileExploreViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic) BOOL sortByName;
@property(nonatomic, strong) NSString *path;
@property(nonatomic, strong) NSMutableArray<NSString*> *file_list;
@property(nonatomic, strong) NSMutableArray<NSString*> *directory_list;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation FileExploreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 初始化文件目录
    if (self.path == nil) {
        self.path = @"/Users/BurningFish";
    }
    self.file_list = [NSMutableArray array];
    self.directory_list = [NSMutableArray array];
    self.sortByName = NO;
    
    self.navigationItem.title = self.path;
    
    [self initFileData];
    
}

- (void)initFileData {
    NSArray<NSString*> *getFiles;
    getFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:nil];
    
    BOOL isDirectory;
    //读取文件名
    for(NSString* filename in getFiles) {
        // 过滤隐藏文件
        if ([filename hasPrefix:@"."]) {
            continue;
        }
        //加上路径前缀
        NSString *filepath = [self.path stringByAppendingPathComponent:filename];
        
        //NSLog(filepath, @"\n");
        
        if([[NSFileManager defaultManager] fileExistsAtPath: filepath isDirectory: &isDirectory]) {
            if(isDirectory) {
                [self.directory_list addObject:filename];
            } else {
                [self.file_list addObject:filename];
            }
        }
    }
}

#pragma mark ------------ UITableViewDataSource ------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.directory_list.count;
    } else if (section == 1) {
        return self.file_list.count;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellID = [NSString stringWithFormat:@"cellID:%zd", indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    if(indexPath.section == 0) {
        cell.imageView.image = [UIImage imageNamed:@"icon_directory.png"];
        cell.textLabel.text = self.directory_list[indexPath.row];
        //设置附加按钮样式
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if(indexPath.section == 1) {
        cell.imageView.image = [UIImage imageNamed:@"icon_file.png"];
        cell.textLabel.text = self.file_list[indexPath.row];
    }
    
    return cell;
}


#pragma mark ------------ UITableViewDelegate ------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        NSString *filename = self.directory_list[indexPath.row];
        NSString *filepath = [self.path stringByAppendingPathComponent:filename];
        
        // 通过storyBoardID创建新的Controller
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        FileExploreViewController *newController = [storyboard instantiateViewControllerWithIdentifier:@"FileExploreViewController"];
        
        newController.hidesBottomBarWhenPushed = YES;
        newController.path = filepath;
        
        [self.navigationController pushViewController:newController animated:YES];
        
    } else if(indexPath.section == 1) {
        NSString *filename = self.file_list[indexPath.row];
        NSString *filepath = [self.path stringByAppendingPathComponent:filename];
        
        FileDetialViewController *newController = [[FileDetialViewController alloc] initWithPath:filepath];
        [self.navigationController pushViewController:newController animated:YES];
    }
}

// 每行的高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}


- (IBAction)onButtonClick:(id)sender {
    if (self.sortByName == YES) return;
    
    [self.directory_list sortUsingSelector:@selector(compare:)];
    [self.file_list sortUsingSelector:@selector(compare:)];
    
    //刷新&动画效果
    //[self.tableView reloadData];
    [UIView transitionWithView: self.tableView
                      duration: 0.35f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
     {
         [self.tableView reloadData];
     }
                    completion: ^(BOOL isFinished)
     {
     }];
    
    self.sortByName = YES;
}


@end
