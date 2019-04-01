第一周周报

Objective-c是C语言的扩展，是对象化的C，因此也是面向对象的，其语法上与C大致相同。这里主要总结一下其与C区别较大的特性。



#### 消息传递机制

在C语言中，函数的调用是静态绑定的，每一个方法必须属于某个类别，并在编译时就已绑定。

而O-C中的方法调用则使用了消息传递的机制，这是动态绑定的。对象之间可以相互传递消息，当一个对象收到消息后，会决定调用哪个方法来处理该消息，这个过程发生在程序运行期间，并可以在运行时发生改变。

给一个对象发送消息的语法如下：

```objective-c
[obj method: argument];
```

- obj是消息的接收者(receiver)
- method是选择器(selector)，即处理消息的方法
- argument是消息的参数

选择器与参数合起来即为"消息"。在编译时，该语句会被转换成一条C语句：

```c
objc_msgSend(obj, @selector(method:), argument);
```

`void objc_msgSend(id self, SEL cmd, …)`是一个参数可变的函数，第一个参数为消息接收者，第二个参数为选择器（方法的名字），之后的参数即为消息参数。

该函数会根据选择器中的方法名称在接收者所属类对方法列表中寻找相应的方法来处理消息，若在当前类中未找到该方法，则会沿继承体向上查找。当找到方法时，跳转至其代码实现，如果最终都没找到，就会进行消息转发。



#### 消息转发机制

对象有可能会收到无法处理的消息，此时程序会抛出异常，但不会崩溃。此外也可以利用消息转发机制来决定对象如何处理未知的消息。

消息转发分多个阶段，首先是动态方法解析，对象会调用其所属类的一个方法：

```objective-c
+ (BOOL)resolveInstanceMethod:(SEL)selector;
```

该方法决定这个类能否为这个未知的消息新建一个实例方法来进行处理（前提是相关代码已经写好）。如果返回值为真，则使用该动态创建的实例方法来处理消息。

若返回值为假，则进入下一步。接下来接收者对象会调用另一个方法：

```objective-c
- (id)forwardingTargetForSelector:(SEL)selector
```

该方法决定是否能让一个备选接收者来代替处理该消息，若找到了备选接收者，则返回该备选对象，将消息转发给它。

若找不到备选，则返回nil，进入下一步。这一步会调用以下方法：

```objective-c
- (void)forwardInvocation:(NSInvocation *)invocation
```

该方法会改变调用目标，使消息在新目标上得以调用，并且可以对消息进行修改，比如修改参数或替换选择器。在实现该方法时若某调用操作不应由本类来处理，则需要沿继承体向上调用超类中的同名方法，若最终到NSObject仍无法处理时，则会抛出异常，表明该消息最终并未得到处理。



#### 类

O-C中的类包含两个部分：

- 定义(interface)：类的声明，数据成员和方法的定义。
- 实现(implementation)：类方法的实际代码。

##### Interface

定义部分以`@interface`开始，以`@end`结束：

```objective-c
@interface MyClass : ParentClass {
  int	var1;
  id	var2;
}

+(return_type) class_method;
-(return_type) instance_method;
@end
```

方法前的+号代表类方法，类似C++中的静态函数，- 号代表实例方法。方法可以带有参数：

```objective-c
-(return_type) instance_method: (type)argument1;
```

此外O-C函数的参数还能插在函数名称之间，比如：

```objective-c
-(void)insertObject: (id)anObject atIndex: (NSInteger)index;
```

该函数有两个参数：`anObject`和`index`，其完整的名称是`insertObject:atIndex:`

##### Implementation

定义部分以`@implementation`开始，以`@end`结束：

```objective-c
@implementation MyClass {
  int var3;
}

+(return_type) class_method {
  //...
}
-(return_type) instance_method {
  //...
}
@end
```

Interface和Implementation部分均可以定义成员变量，但是两者变量的访问权限不同，Interface中默认为protected，Implementation中默认为private。



#### 常用数据类型

O-C中常用的数据类型有`NSString`, `CGfloat`, `NSInteger`, `BOOL`, `NSNumber`等。

##### NSString

`NSString`为字符串类型，用`@""`表示。字符串对象的创建方法有多种。

```objective-c
//直接创建
NSString *str0 = @"Hello World\n";
//格式化创建
NSString *str1 = [NSString stringWithFormat:@"number: %d, name: %s", 1, @"ctp"];
//从cstring创建
NSString *str2 = [NSString stringWithCString:"Hello World\n" encoding:NSASCIIStringEncoding];
```

NSString的其他常用方法：

```objective-c
//字符串拼接
NSString *str = [str0 stringByAppendingString:str1];
//字符串比较
[str0 isEqualToString:str1];
//截取字符串到目标位置
str = [str0 substringToIndex:5];
//从目标位置开始截取字符串
str = [str0 substringFromIndex:5];
//范围截取
NSRange rang = NSMakeRange(2, 5);
str = [str0 substringWithRange:rang];
//字符串搜索，rang.location为起始位置，rang.length为长度
rang = [str0 rangeOfString:@"Hello"];
//字符串替换
str = [str0 stringByReplacingCharactersInRange:rang withString:@"Bye"];
```

##### NSIntger和NSUInteger

NSUInteger和NSInteger并不是类，而是用typedef对int, long, unsigned int等基本类型的新定义。其优点是会识别当前操作系统的位数选择最大数值。

```objective-c
#if __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64
typedef long NSInteger;
typedef unsigned long NSUInteger;
#else
typedef int NSInteger;
typedef unsigned int NSUInteger;
#endif
```

##### NSNumber

NSNumber是对C中的char, int, float等基本类型的封装。

NSNumber可以用任意基础数据类型对其初始化，以int为例：

```objective-c
NSNumber num0=[NSNumber numberWithInteger:10];
NSNumber num1=[[NSNumber alloc] initWithInt:10];
```

num.objCType可以得到NSNumber对象的数据类型编码。

将基本类型数据封装到NSNumber中后，就可以通过下面的实例方法重新获取它：

```objective-c
- (char) charValue;
- (int) intValue;
- (float) floatValue;
```



#### 数组

O-C中使用的数组类型为`NSArray`和`NSMutableArray`，前者是不可变数组，后者是可变数组，不可变数组创建后元素个数不能发生变化，而可变数组可以自由增删改。数组中不能存储基本类型数据，而是存储**对象**。

##### NSArray

初始化：

```objective-c
//初始化，以nil结尾
NSArray *arr0 = [[NSArray alloc] initWithObjects:@"1", @"2", @"3", nil];
//便利构造器，以nil结尾
NSArray *arr1 = [NSArray arrayWithObjects:@"1", @"2", @"3", nil];
//字面量
NSArray *arr2 = @[@"1", @"2", @"3"];
```

常用方法：

```objective-c
//元素个数
NSInteger count = arr0.count;
//获取元素
NSString *str = [arr0 objectAtIndex:2];
//获取下标
NSInteger index = [arr0 indexOfObject:@"2"];
//打印整个数组
NSLog(@"%@", arr);
//判断是否包含某个元素　
[arr0 containsObject:@"2"];
//快速枚举遍历数组
for(NSString *s in arr0) {
  NSLog(@"%@", s);
}
```

##### NSMutableArray

NSMutableArray继承自NSArray，包含NSArray的所有方法，并且可以自由增删改元素。

创建：

```objective-c
NSMutableArray *arr0 = [[NSMutableArray alloc] initWithCapacity:0];
NSMutableArray *arr1 = [NSMutableArray arrayWithCapacity:0];
```

常用方法：

```objective-c
//增加元素
[arr0 addObject:@"1"];
//在指定位置插入元素
[arr0 addObject:@"2" atIndex:1];
//移除指定元素
[arr0 removeObject:@"1"];
//移除所有元素
[arr0 removeAllObjects];
//按下标移除元素
[arr0 removeObjectAtIndex:2];
//替换元素
[arr0 replaceObjectAtIndex:2 withObject:@"3"];
//交换元素位置
[arr0 exchangeObjectAtIndex:1 withObjectAtIndex:2];
```

##### 二维数组

O-C中并没有多维数组的概念，但是可以通过在数组中存放数组来实现：

```objective-c
NSMutableArray *matrix = [[NSMutableArray alloc] init];
NSMutableArray *arr0 = [NSMutableArray arrayWithObjects:@"1", @"2", @"3", nil];
NSMutableArray *arr1 = [NSMutableArray arrayWithObjects:@"4", @"5", @"6", nil];
NSMutableArray *arr2 = [NSMutableArray arrayWithObjects:@"7", @"8", @"9", nil];

[matrix addObject:arr0];
[matrix addObject:arr1];
[matrix addObject:arr2];
//获取i j位置的元素
((NSMutableArray *)matrix[i])[j] = @"666";
```





#### Coding

HelloWorld:

```objective-c
#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool { 
        NSLog(@"Hello, World!");
    }
    return 0;
}
```

打印螺旋矩阵：

```objective-c
#import <Foundation/Foundation.h>
#define ADD_ELEMENT_TO_MATRIX if(ou > z) break;\
    ((NSMutableArray *)matrix[i])[j] = [NSNumber numberWithInt:ou];\
    ou ++;

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSInteger n = 5, c = 0;
        int ou = 1;
        NSInteger z = n * n;
        
        NSMutableArray *matrix = [[NSMutableArray alloc] init];
        for(NSInteger i = 0; i < n; i ++) {
            [matrix addObject: [NSMutableArray arrayWithCapacity: n]];
            for(NSInteger j = 0; j < n; j ++) {
               ((NSMutableArray *)matrix[i])[j] = [NSNumber numberWithInt:0];
            }
        }
        
        while(ou <= z) {
            NSInteger i = 0, j = 0;
            for(i += c,j += c; j < n - c; j ++) {
                ADD_ELEMENT_TO_MATRIX
            }
            for(j --, i ++; i < n - c; i ++)
            {
                ADD_ELEMENT_TO_MATRIX
            }
            for(i --, j --; j >= c; j --)
            {
                ADD_ELEMENT_TO_MATRIX
            }
            for(j ++, i --; i >= c + 1; i --)
            {
                ADD_ELEMENT_TO_MATRIX
            }
            c ++;
        }
        
        NSString *output = @"\n";
        for(NSMutableArray *m in matrix) {
            for(NSNumber *num in m) {
                output = [output stringByAppendingString:[NSString stringWithFormat:@"%5d ", num.intValue]];
            }
            output = [output stringByAppendingString: @"\n"];
        }
        NSLog(@"%@", output);
    }
    return 0;
}
```

输出结果：

![屏幕快照 2019-03-19 下午10.56.12](/Users/BurningFish/Desktop/ios-learn/assets/屏幕快照 2019-03-19 下午10.56.12.png)