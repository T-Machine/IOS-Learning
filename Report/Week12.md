#  IOS移动应用开发实践报告12（第15周）

##  本周总体学习情况

本周主要实现的是设置页面的UI和逻辑，为了方便操作，封装了一个从底部弹出视图的BottomBounceView。其中使用了block，因此也顺便学习了一些相关的知识点。

## Block

Block是封装了函数调用以及函数调用环境的OC对象，可以看成是一种匿名函数。Block允许开发者在两个对象之间将任意的语句当做数据进行传递。block的实现具有封闭性(closure)，但又能够很容易获取上下文的相关状态信息。

#### 使用：

声明并定义一个简单的block：

 首先`^`符号将addBlock声明为一个block对象，其返回值为int类型，参数为两个int变量，名称分别为a和b：

```objective-c
int (^addBlock)(int, int) = ^(int a, int b) { 
	return a + b; 
}
```

此外可以利用typedef为Block进行重命名：

```objective-c
typedef int (^ AddBlock)(int a, int b);

int x, y;
AddBlock block = ^(int a, int b) {
  return a + b;
}
int n = block(x, y);
```

#### Block的类型

根据Block在内存中的位置不同，可以分为三种类型：`NSGlobalBlock`, `NSStackBlock`, `NSMallocBlock`:

- NSGlobalBlock：位于数据区中
- NSStackBlock：位于栈区中
- NSMallocBlock：位于堆区中

#### __block关键字

在block的代码块中不能修改外部定义的变量，并且在给block赋值时，就已经堆代码块里的变量做了值的拷贝，因此是只读的。比如下面的block：

```objective-c
int a = 2;
int (^addBlock) (int) = ^(int b) {
  return a + b;
}
a += 2;
int x = addBlock(3);
NSLog(@"%d", x);
// 输出结果为2 + 3 = 5； 而不是4 + 3 = 7
```

由于a是在block外部定义的，该block的代码块在编译时，取的a的值为上面的2，并且不会修改，因此即使下面a的值改变了，也不会影响block中的a。

如果要使外部变量在block中可改变，则需要给该变量加上`__block`关键字，这样block中代码块执行时会取该变量的最新的值。



## Coding

BottomBounceView的视图由三部分组成，首先是自身的view，作为半透明的黑色遮罩层；其次是从底部向上弹出的contentView；最后是contentView中的各种控件，比如文本输入框或时间选择器，以及确认和取消按钮。

运行流程：在主视图A中加入BottomBounceView子视图B，在B中的文本框输入内容，或者在DatePicker中选择时间，点击"确认"按钮后视图B消失，并利用block将更改的值传回A。

#### BottomBounceView.h

首先在头文件中声明要用到的block，并使用typedef进行重命名，方便调用：

```objective-c
typedef void (^ReturnTextBlock)(NSString *text);
typedef void (^ReturnDateBlock)(NSDate *date);

// block
@property (nonatomic, copy, nullable) ReturnTextBlock returnTextBlock;
@property (nonatomic, copy, nullable) ReturnDateBlock returnDateBlock;
```

此外还要定义用于在A中加入B视图并给block赋值的方法：

```objective-c
- (void) showTextFieldInView:(UIView *)view withReturnText:(ReturnTextBlock)block;
- (void) showDatePickerInView:(UIView *)view withReturnDate:(ReturnDateBlock)block;
```

#### BottomBounceView.m

在用于显示BottomBounce视图的方法中，需要传人。以底部时间选择器为例，首先给相应的block赋值，然后加入DatePicker控件，最后在主视图中加入并显示子视图。

```objective-c
- (void) showDatePickerInView:(UIView *)view withReturnDate:(ReturnDateBlock)block {
    self.returnDateBlock = block;
    [self addDatePicker];
    [self showInView:view];
}
```

加入DatePicker控件，进行相应的设置：

```objective-c
- (void)addDatePicker {
    self.contentHight = 250;
    [self.contentView setFrame:CGRectMake(0, self.frame.size.height - self.contentHight, self.frame.size.width, self.contentHight)];
    if(_datePicker == nil) {
        _datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(25, 40, self.frame.size.width - 50, self.contentHight - 80)];
        // 设置地区: zh-中国
        _datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"zh"];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        // 设置当前显示时间
        [_datePicker setDate:[NSDate date] animated:YES];
        // 设置显示最大时间（此处为当前时间）
        [_datePicker setMaximumDate:[NSDate date]];
    }
    [_contentView addSubview:_datePicker];
}
```

在显示视图的方法中，首先将自身遮罩视图和底部弹出视图都加入到调用者的子视图中，然后定义动画效果，让弹出视图从下方移动出来：

```objective-c
- (void)showInView:(UIView *)view {
    if (!view) {
        return;
    }
    
    [view addSubview:self];
    [view addSubview:_contentView];
    
    [self.contentView setFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, self.contentHight)];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
        [self.contentView setFrame:CGRectMake(0, self.frame.size.height - self.contentHight, self.frame.size.width, self.contentHight)];
    } completion:nil];
}
```

在确认按钮的点击事件中，调用被赋值的block，然后让B视图消失：

```objective-c
- (void)okButtonClick {
    if (self.returnTextBlock != nil && self.textView != nil) {
        self.returnTextBlock(self.textView.text);
    }
    if(self.returnDateBlock != nil && self.datePicker != nil) {
        self.returnDateBlock(self.datePicker.date);
    }
    [self disMissView];
}
```

在进行视图的移除时，首先定义一个动画效果，让遮挡层变为全透明，并让底部的控件下移。在动画结束之后，首先将自身从A视图（SuperView）中移除，再将各个子控件从自身视图中移除，最后将各个block都置为nil，方便下一次赋值：

```objective-c
- (void)disMissView {
    [self.contentView setFrame:CGRectMake(0, self.frame.size.height - self.contentHight, self.frame.size.width, self.contentHight)];
    [UIView animateWithDuration:0.3f
                     animations:^{
                         self.alpha = 0.0;
                         [self.contentView setFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, self.contentHight)];
                     }
                     completion:^(BOOL finished){
                         [self removeFromSuperview];
                         [self.contentView removeFromSuperview];
                         [self.textView removeFromSuperview];
                         [self.datePicker removeFromSuperview];
                         self.returnTextBlock = nil;
                         self.returnDateBlock = nil;
                     }];
}
```

#### 主视图A

要在一个视图A中显示BottomBounceView，只需要创建一个BottomBounceView对象，然后调用相应的显示方法并设置回调block即可：

```objective-c
self.bbv = [[BottomBounceView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
[self.bbv showDatePickerInView:self.view withReturnDate:^(NSDate *date) {
		NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
		[dateFormat setDateFormat:@"yyyy-MM-dd"];//设定时间格式
		NSString *dateString = [dateFormat stringFromDate:date];
		NSLog(@"###current date - %@\n", dateString);
}];
```









