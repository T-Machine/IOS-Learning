//
//  FileDetialViewController.m
//  FileReader2
//
//  Created by 陈统盼 on 2019/3/24.
//  Copyright © 2019 TMachine. All rights reserved.
//

#import "FileDetialViewController.h"

@interface FileDetialViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSString *path;
@property(nonatomic, strong) NSMutableArray<NSString*> *attribute_keys;
@property(nonatomic, strong) NSMutableArray<id> *attribute_values;

@end

@implementation FileDetialViewController

- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        self.path = path;
    }
    
    NSLog(@"init with path: @%@\n", path);
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.attribute_keys = [NSMutableArray array];
    self.attribute_values = [NSMutableArray array];
    
    self.navigationItem.title = self.path;
    
    self.tableView = ({
        UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView;
    });
    
    [self.view addSubview:self.tableView];
    [self initInfo];
    
}

- (void)onClickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initInfo {
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:self.path error:nil];
    
    NSLog(@"%@", dict);
    for (NSString *key in dict) {
        [self.attribute_keys addObject:key];
        [self.attribute_values addObject:dict[key]];
    }
    
}


#pragma mark ------------ UITableViewDataSource ------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.attribute_keys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellID = @"cellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    if(indexPath.row == 0) {
        cell.textLabel.text = self.attribute_keys[indexPath.section];
    } else if(indexPath.row == 1) {
        // 注意类型
        cell.textLabel.text = [NSString stringWithFormat:@"%@", self.attribute_values[indexPath.section]];
    }
    
    return cell;
}


#pragma mark ------------ UITableViewDelegate ------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
