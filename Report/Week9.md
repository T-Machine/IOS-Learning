#  IOS移动应用开发第九周实践报告

## 本周总体学习情况

本周在上周实现内容上完善了首页新闻列表的预览图片显示功能，利用了YBImageBrowser，使得浏览大图的操作更简便，同时效果也更好。此外还实现了TableViewCell的高度自适应，以及多图片显示位置的自适应。

## YBImageBrowser的使用

YBImageBrowser库是IOS中的图片浏览器库，其功能强大，性能优越，且易于扩展。这里使用该库来实现新闻列表页面的点击预览图后放大浏览的功能。

### 一些特性：

- 支持 GIF，APNG，WebP 等本地和网络图像类型
- 支持系统相册图像和视频
- 支持高清图浏览
- 支持数组或协议配置数据源
- 支持预加载

### 安装：

Podfile：`pod 'YBImageBrowser'`

### 引入：

头文件：`<YBImageBrowser/YBImageBrowser.h>`

### 使用方法：

#### 主体类：

图片浏览器的主体类为`YBImageBrowser`，使用时需要指定数据源，即要显示的内容。此外还可以指定`currentIndex`，即当前显示的数据源个体的序号，当切换显示的数据源个体时，该属性会相应地改变。完成属性的设置之后调用`show`即可显示全屏的图片浏览器，并且可以左右滑动切换。

```objective-c
YBImageBrowser *browser = [YBImageBrowser new];
browser.dataSource = self;
browser.dataSourceArray = @[data0, data1, data2];
browser.currentIndex = index;
[browser show];
```

#### 数据源：

给`YBImageBrowser`指定数据源的方法有两种。

**第一种**是像上面的代码一样，对`dataSourceArray`属性进行赋值，该属性是一个由数据源个体组成的数组。数据源个体的类型为`id<YBImageBrowserCellDataProtocol>`，该库中已经在该Protocol下实现了两个数据源类：`YBImageBrowseCellData`和`YBVideoBrowseCellData`，分别对应图片和视频对象。对于图片对象，创建之后需要设置`url`和`sourceObject`，其中`url`为图片地址，用于获取网络图片对象（由SDWebImage支持）；`sourceObject`为图片所属的控件（UIImageView），用于确定图片在原frame中的位置，在显示大图时根据其位置播放相应的缩放电话：

```objective-c
YBImageBrowseCellData *data0 = [YBImageBrowseCellData new];
data0.url = nsUrl;
data0.sourceObject = imgView;   
```

**第二种**方法是使用代理来设置数据源，需要实现的协议为`<YBImageBrowserDataSource>`，必须的方法有两个：

```objective-c
- (NSUInteger)yb_numberOfCellForImageBrowserView:(nonnull YBImageBrowserView *)imageBrowserView
```

```objective-c
- (id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index
```

前者需要返回数据源个体的总数，后者返回对应index的数据源个体，与UITableView的DataSource设置十分相似。

对于第一种方法，YBImageBrowser持有数据模型，并且可以缓存数据处理结果，从而提高用户交互性能。

对于第二种方法，可以避免让YBImageBrowser持有过多数据从而减少内存负担。

#### ToolBar:

YBImageBrowser组件提供了默认的ToolBar(`defaultToolBar`)，可以用于显示页码：

![屏幕快照 2019-05-13 下午11.04.38](assets/屏幕快照 2019-05-13 下午11.04.38.png)

## Coding

### 在TableViewCell中显示多张网络图片

#### 数据模型

首先定义一个NewsItem类，用于存放新闻的标题和预览图的URL。

```objective-c
@interface NewsItem : NSObject
@property (nonatomic,strong) NSString *discription;
@property (nonatomic,strong) NSMutableArray<NSString*> *imgUrlArray;
@end
```

#### 自定义TableViewCell

然后需要定义一个继承自UITableViewCell的类，属性包括一个UILabel，一个对应的NewsItem数据类，和一个UIImageView数组：

```objective-c
@interface NewsTableViewCell : UITableViewCell
@property (nonatomic,strong) NewsItem *newsItem;
@property (assign,nonatomic) UILabel *_discription;
@property (nonatomic,strong) NSMutableArray<UIImageView *> *imgViews;
@end
```

图片的布局和显示需要在设置了NewsItem之后才能进行，因此在NewsItem的set方法中进行相关操作。

首先获取NewsItem中的图片数量，创建相同数量的UIImageView，为呈现出九宫格的效果，需要计算出它们各自的frame。然后将它们添加到`imgViews`数组中，并设置一个Tag，方便后续的操作。

此外还要计算出Cell的高度，实现高度自适应。

之后将各个图片的contentMode设为`UIViewContentModeScaleAspectFill`，即按比例缩放至填充整个控件，再将clipsToBounds设为`YES`，即允许剪裁，保证图片不超出设置的frame的范围。

最后是图片资源的获取，对于每个Url，首先利用`SDImageCache`类检查当前的Cache中是否存在该url的缓存，如果存在，则直接从Cache中取出图片资源来使用，如果不存在，则使用`sd_setImageWithURL:`来从网络获取图片。

```objective-c
-(void) setNewsItem:(NewsItem *)newsItem {
    _newsItem = newsItem;
    [_discription setText:newsItem.discription];
    NSInteger count = [newsItem getImgNum];
    CGRect frame = [self frame];
    // calculate size
    CGFloat imgSize = (self.contentView.bounds.size.width - 100) / 3;
    frame.size.height = ((count-1)/3 + 1) * (imgSize+10) + 60;
    self.frame = frame;
    
    for(int i = 0; i < count; i ++) {
        UIImageView *img = [[UIImageView alloc] init];
        if(count == 4) {
            NSInteger row = i/2;
            [img setFrame:CGRectMake(50+(10+imgSize)*(i%2), 40+(10+imgSize)*row, imgSize, imgSize)];
        }
        else {
            NSInteger row = i/3;
            [img setFrame:CGRectMake(50+(10+imgSize)*(i%3), 40+(10+imgSize)*row, imgSize, imgSize)];
        }
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.clipsToBounds = YES;
        [img setTag:i];
        [self.imgViews addObject:img];
        [self.contentView addSubview:img];
    }
    
    for(int i = 0; i < count; i ++) {
        NSString *imgUrl = newsItem.imgUrlArray[i];
        UIImageView *img = self.imgViews[i];
        UIImage *cachedImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imgUrl];
        if (!cachedImg) {
            [imgView sd_setImageWithURL:[NSURL URLWithString:imageURL] placeholderImage:[UIImage imageNamed:@"loading.jpg"]];
        }else{
            img.image = cachedImg;
        }
    }
}
```

#### DataSource

在`cellForRowAtIndexPath:`方法中，首先为每条新闻创建相应的NewsItem类，将其赋值到新建的TableViewCell的属性上。然后获取cell中的imgViews数组的各个图片组件，将它们的`userInteractionEnabled`属性设为YES，使得用户可以与之交互，这样就能添加点击手势事件了：

```objective-c
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellID = @"cellID";
    NewsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (nil == cell) {
        cell = [[NewsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    NewsItem *newsItem;
    newsItem = self.newsList[indexPath.row];
    [cell setNewsItem:newsItem];    
    for(int i = 0; i < newsItem.getImgNum; i ++) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onImgClick:)];
        cell.imgViews[i].userInteractionEnabled = YES;
        [cell.imgViews[i] addGestureRecognizer:tapGesture];
    }   
    return cell;
}
```

#### DataDelegate

为实现Cell的高度自适应，在setNewsItem方法中设置了frame的高度后，需要在controller的DataDelegate中进行相应的设置，通过`[self tableView:_tableView cellForRowAtIndexPath:indexPath]`来获取实际的高度值，作为`heightForRowAtIndexPath:`方法的输出：

 ```objective-c
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:_tableView cellForRowAtIndexPath:indexPath];
    return cell.frame.size.height;
}
 ```



### YBIMageBrowser显示大图

主类需要实现`YBImageBrowserDataSource`协议，这里用了两个数组来存放当前要显示的图片的相关数据内容，一个用来放图片的url，另一个存放相应的UIImageView：

```objective-c
@property (nonatomic,strong) NSMutableArray<NSString *> *YB_urlStr_array;
@property (nonatomic,strong) NSMutableArray<UIImageView *> *YB_imgView_array;
```

在`yb_numberOfCellForImageBrowserView:`中，返回其中一个数组的count值，即可得到需要显示的图片总数：

```objective-c
- (NSUInteger)yb_numberOfCellForImageBrowserView:(nonnull YBImageBrowserView *)imageBrowserView {
    return self.YB_imgView_array.count;
}
```

在另一个设置数据源个体的方法中，根据当前显示的图片index来获取数组中对应位置的内容，赋值到新建的`YBImageBrowseCellData`对象上，然后返回该对象：

```objective-c
- (nonnull id<YBImageBrowserCellDataProtocol>)yb_imageBrowserView:(nonnull YBImageBrowserView *)imageBrowserView dataForCellAtIndex:(NSUInteger)index {
    YBImageBrowseCellData *data = [YBImageBrowseCellData new];
    data.url = [NSURL URLWithString:self.YB_urlStr_array[index]];
    data.sourceObject = self.YB_imgView_array[index];
    return data;
}
```

在Cell中的图片手势点击事件中，需要设置YBImageBrowser的数据源并将其展示出来。

首先获取当前点击图片的`superview`，即所在的TableViewCell，从而获取对应的newsItem，就能得到该新闻的图片Url数组以及ImageView数组，赋值到`YB_urlStr_array`和`YB_imgView_array`中。

然后创建新的YBImageBrowser对象，将currentIndex属性设置为被点击的图片的Tag，表示该图片在当前图片数组中的位置。最后调用show来显示大图。

```objective-c
- (void) onImgClick:(UITapGestureRecognizer *)tap {
    UIImageView *imgView = (UIImageView *)tap.view;
    UIView *contentView = (UIView *)[tap.view superview];
    NewsTableViewCell *cell = (NewsTableViewCell *)[contentView superview];
    // 设置数据源代理并展示
    self.YB_urlStr_array = cell.newsItem.imgUrlArray;
    self.YB_imgView_array = cell.imgViews;
    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSource = self;
    browser.currentIndex = (NSUInteger)imgView.tag;
    [browser show];   
}
```



### 清除缓存

在YBImageBrowser的官方Demo中有一个清除缓存按钮，利用了`SDImageCache`类的方法来处理应用缓存，在相应的回调函数中调用`yb_showHookTipView`方法来显示提示框。

```objective-c
// clear cache
- (void)clickClearButton:(UIButton *)sender {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [[UIApplication sharedApplication].keyWindow yb_showHookTipView:@"Clear successful"];
    }];
}
```

