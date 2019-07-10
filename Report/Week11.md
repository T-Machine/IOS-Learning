#  IOS移动应用开发实践报告11（第14周）

## 本周主要学习内容

本周主要实现的内容是从网络访问获取数据后，利用ReactiveOC来发送信号，使ViewModel与Controller进行通信，通知后者刷新控件视图。涉及到的知识点有：

- viewMode在父页面和子页面中的共用
- 用AFNetworking进行网络访问
- 用ReactiveOC进行通信



## 实现的内容

父页面中有一个PageView，包含了5个ListView子页面，每个子页面都有一个TableView和NSMutableArray用于显示不同的新闻列表，并且父页面持有ViewModel。ViewModel中有5个NSMutableArray，分别对应5个子页面。需要做的是将这5个数组分别绑定到5个子页面的数组中，ViewModel负责数据的获取，并在获取之后通知子页面更新视图。

首先在ViewModel中定义一个ReactiveOC信号`reload`用于和子页面的通信：

```objective-c
@property(nonatomic, strong) RACSubject *reload;
```

再定义一个从网络API获取新闻列表的方法，利用`AFNetworking`来进行相关的网络请求操作，从success回调的responseObject中解析出JSON数据。其中包括一个NSTimeInterval时间戳对象，由于IOS中的时间戳和JavaScript中的单位不同，所以这里需要先进行单位换算，然后再转换成相应的字符串。最后将解析出的数据全部存入对应的NSMutableArray中，并用`sendNext`方法让`reload`发送信号。

```objective-c
- (void)loadNewsTo: (NSMutableArray*)list withURL: (NSString*)url {
    [self.manage GET:url parameters:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSMutableArray *result = [[NSMutableArray alloc] init];
        NSArray *newData = responseObject[@"data"];
        for(int i = 0; i < [newData count]; i++){
            News *news = [[News alloc] init];
            [news setTitle: newData[i][@"title"]];
            [news setAuthor: newData[i][@"author"]];
            [news setComments: [[NSString alloc] initWithFormat:@"%@", newData[i][@"comments"]]];
            NSTimeInterval interval = [newData[i][@"time"] longLongValue];
            interval /= 1000.0;
            [news setTime: [NSDate dateWithTimeIntervalSince1970: interval]];
            NSData *jsonString = [newData[i][@"image_infos"] dataUsingEncoding:NSUTF8StringEncoding];
            NSArray *dic = [NSJSONSerialization JSONObjectWithData:jsonString
                                                           options:NSJSONReadingMutableContainers
                                                             error:nil];
            news.images = [[NSMutableArray alloc] init];
            for(int j = 0; j < [dic count]; j++){
                NSString *prefix = dic[j][@"url_prefix"];
                NSString *url = dic[j][@"web_uri"];
                [ news.images addObject: [prefix stringByAppendingString:url]];
            }
            if([news.images count] == 0){
                news.tag = 0;
            } else {
                news.tag = 1;
            }
            [result addObject: news];
        }
        [list removeAllObjects];
        [list addObjectsFromArray:result];
        [self.reload sendNext:@"success"];
        NSLog(@"[load news] success");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"[load news] fail: %@", url);
    }];
}
```

在ListView子页面的`bindViewModel`方法中设置`reload`事件的订阅，当接收到`reload`发出的信号时，在主线程中更新tableView的数据。使之前加载的新闻显示出来。

```objective-c
- (void)bindViewModel {
    [self.viewModel.reload subscribeNext:^(id  _Nullable x) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }];
}
```

整个结构的运行流程是：

- 父页面将各个ListView子页面中的NSMutableArray设为ViewModel中对应的数组。
- 父页面调用ViewModel中的网络访问方法。
- ViewModel从网络得到数据后更新NSMutableArray，然后发送信号给ListView。
- ListView收到信号后刷新tableview显示数据。



## Protocol

**Protocol**的定义如下：

> 协议是任何类都能够选择实现的程序接口。协议能够使两个没有继承关系的类相互交流并完成特定的目的，因此它提供了除继承外的另一种选择。任何能够为其他类提供有用行为的类都能够声明接口来匿名的传达这个行为。任何其他类都能够选择遵守这个协议并实现其中的一个或多个方法，从而利用这个行为。如果协议遵守者实现了协议中的方法，那么声明协议的类就能够通过遵守者调用协议中的方法。

- 一个类可以遵循1个或多个协议。
- 任何类只要遵循了Protocol就相当于拥有了Protocol的所有的方法声明。

- NSObject是一个基类，任何其他类都要继承它 ；NSObject是一个基协议，声明了最基本的方法（description、retain、release等等），每个新协议都遵循它。



## AFNetworking

`AFNetworking`常用的用于处理网络请求的第三方库，它对HTTP协议和IOS的网络编程相关操作进行了封装。

`AFNetworking`分为若干个模块：

- Serilazitoin
- Security
- Reachability
- NSURLSession

### Serialization

这一模块中主要的类为涉及两个协议：`AFURLRequestSerialization`和`AFURLResponseSerialization`。

#### AFHTTPRequestSerializer

`AFHTTPRequestSerializer`类实现了`AFURLRequestSerialization`协议，可以用于普通的参数请求和需要上传文件的参数请求。

对于前者，使用的API为：

```objective-c
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                 URLString:(NSString *)URLString
                                parameters:(nullable id)parameters
                                     error:(NSError * _Nullable __autoreleasing *)error;
```

后者的API为：

```objective-c
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                              URLString:(NSString *)URLString
                                             parameters:(nullable NSDictionary <NSString *, id> *)parameters
                              constructingBodyWithBlock:(nullable void (^)(id <AFMultipartFormData> formData))block
                                                  error:(NSError * _Nullable __autoreleasing *)error;
```

在上传文件时需要用到一个`formData`对象，这个对象实现了`AFMultipartFormData`协议，该协议定义了上传文件的相关方法，比如：

- 通过URL确定上传的文件：

  ```objective-c
  - (BOOL)appendPartWithFileURL:(NSURL *)fileURL
                           name:(NSString *)name
                          error:(NSError * _Nullable __autoreleasing *)error;
  ```

- 通过NSInputStream上传文件：

  ```objective-c
  - (void)appendPartWithInputStream:(nullable NSInputStream *)inputStream
                               name:(NSString *)name
                           fileName:(NSString *)fileName
                             length:(int64_t)length
                           mimeType:(NSString *)mimeType;
  ```

- 通过NSData上传文件：

  ```objective-c
  - (void)appendPartWithFileData:(NSData *)data
                            name:(NSString *)name
                        fileName:(NSString *)fileName
                        mimeType:(NSString *)mimeType;
  ```

`AFHTTPRequestSerializer`还有一些子类，这些子类可以用于对请求参数的格式进行扩展，比如`AFJSONRequestSerializer`就可以将参数换成JSON格式。

#### AFHTTPResponseSerializer

`AFHTTPResponseSerializer`类实现了`AFURLResponseSerialization`协议。其主要方法为：

```objective-c
- (BOOL)validateResponse:(nullable NSHTTPURLResponse *)response
                    data:(nullable NSData *)data
                   error:(NSError * _Nullable __autoreleasing *)error;
```

同样`AFHTTPResponseSerializer`也有用于不同数据格式的子类，比如`AFJSONResponseSerializer`用于解析JSON数据，`AFXMLParserResponseSerializer`用于解析XML数据，比较特殊的是`AFImageResponseSerializer`，可以解析图片数据



### NSURLSession

NSURLSession是IOS中用于HTTP请求的类。`AFNetworking`中通过`AFURLSessionManager`类来对NSURLSession进行封装管理，简化了用户进行网络请求的操作。

`AFURLSessionManager`有一个子类`AFHTTPSessionManager` ，它对HTTP请求的各种方式（GET，POST，PUT，DELETE）进行了进一步的封装，比如POST请求的封装如下：

```objective-c
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(id)parameters
                      progress:(void (^)(NSProgress * _Nonnull))uploadProgress
                       success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    NSURLSessionDataTask *dataTask = [self dataTaskWithHTTPMethod:@"POST" URLString:URLString parameters:parameters uploadProgress:uploadProgress downloadProgress:nil success:success failure:failure];

    [dataTask resume];

    return dataTask;
}
```

在请求时只需要提供URL，参数，以及成功失败的回调即可。

此外 可以通过设置不同类型的`Serializer`来改变解析数据的格式：

```objective-c
self.manage = [AFHTTPSessionManager manager];
// 设置请求体为JSON
self.manage.requestSerializer = [AFJSONRequestSerializer serializer];
// 设置响应体为JSON
self.manage.responseSerializer = [AFJSONResponseSerializer serializer];
```



