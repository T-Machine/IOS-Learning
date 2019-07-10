#  IOS移动应用开发实践报告10（第13周）

由于访问API涉及到网络请求方面的知识，包括多线程以及任务队列的使用，因此这周梳理了一下这些内容：

- GCD
- NSOperation & NSOperationQueue
- NSThread



### GCD

在IOS中，GCD用于对任务和队列进行操作，实现并行处理。GCD会自动管理线程的生命周期（创建线程、调度任务、销毁线程），较为方便。

GCD中的任务有同步（sync）和异步（async）两种执行方式，其中异步任务可以开启新线程，而同步执行不具备开启新线程的能力。

```objective-c
// 创建同步任务
dispatch_sync(queue, ^{
    // block
});
// 创建异步任务
dispatch_async(queue, ^{
    // block
});
```

GCD中的队列以FIFO原则存放任务。队列分为串行（**Serial Dispatch Queue**）和并行（**Concurrent Dispatch Queue**）两种，其中并行的队列只有在异步（dispatch_async）的函数下才有效。

使用`dispatch_queue_create`来创建队列，其第一个参数指定队列的唯一标识符，第二个参数指定队列的类型：

```objective-c
// 串行
dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL);
// 并发
dispatch_queue_t queue = dispatch_queue_create(nil, DISPATCH_QUEUE_CONCURRENT);
```

对于串行队列，GCD提供了称为**主队列**的特殊串行队列，通过`dispatch_get_main_queue()`方法获取。所有放在主队列中的任务，都会放到主线程中执行。

对于并发队列，GCD提供了一个全局的并发队列，通过`dispatch_get_global_queue()`获取。



### NSOperation

一般在进行多线程操作时不会直接使用GCD，而是使用NSOperation和NSOperationQueue，这是基于GCD的封装，使用起来比GCD更方便。

与GCD相对应，NSOperation和NSOperationQueue中也有任务和队列的概念。NSOperation是一个抽象类，其子类用于封装各种任务的代码，NSOperationQueue则提供了各种类型的队列，包括主队列和自定义队列，前者在主线程中执行，后者则在后台执行。

NSOperation使用的一般步骤如下：

#### 创建任务

创建任务时可以使用NSOperation的NSInvocationOperation及NSBlockOperation，或者其他自定义的子类。

`NSInvocationOperation`类可以初始化一个操作，该操作在一个指定的对象上去调用一个selector：

```objective-c
NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(func1) object:nil];
```

`NSBlockOperation`管理一个或多个block的并发执行：

```objective-c
NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
	// block
}];
```

`NSBlockOperation`中还有一个`addExecutionBlock`方法，可以向Operation中添加额外的操作，当其中包含的操作数量较多时，它们会自动开启新的线程来并发执行：

```objective-c
[op addExecutionBlock:^{
	// block2
}];
```

对于单一的NSOperation对象，可以直接调用`start`方法来执行该任务，这个任务会在当前线程中被执行。

#### 创建队列

与GCD类似，当创建的队列为主队列时，其中的操作都会放到主线程中执行：

```objective-c
NSOperationQueue *queue = [NSOperationQueue mainQueue];
```

而添加到自定义队列中的操作则会放到子线程中执行，因此自定义队列支持并发操作：

```objective-c
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
```

#### 向队列中添加操作

有两种添加操作的方法：

- 将创建好的operation添加到队列中：

  ```objective-c
  - (void)addOperation:(NSOperation *)op;
  ```

- 在block中定义操作，并将block的内容加入到队列中：

  ```objective-c
  - (void)addOperationWithBlock:(void (^)(void))block;
  ```

此外，NSOperationQueue中还有一个重要的属性`maxConcurrentOperationCount`，它用于控制队列中的最大并发操作数。其默认值为-1，即并发执行；值为1时控制为串行执行；值大于1时为有限制的并发执行。



### NSThread

#### 创建及启用

NSThread为IOS中的线程操作对象。可以用于管理线程的生命周期，以及线程同步和线程安全。

新线程在创建时需要指定一个方法作为其执行的任务，在启动线程时就会调用该方法。线程创建之后可以通过`start`方法启动，或者在创建时设置为自动启动：

```objective-c
// 创建并启动线程
NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
[thread start];

// 创建自动启动的线程
[NSThread detachNewThreadSelector:@selector(run) toTarget:self withObject:nil];

// 线程任务
- (void)run {
     NSLog(@"%@", [NSThread currentThread]);
}
```

#### 属性和方法

NSThread中常用的属性有`currentThread`和`mainThread`， 用于获取当前线程及主线程：

```objective-c
@property (class, readonly, strong) NSThread *currentThread;
@property (class, readonly, strong) NSThread *mainThread;
```

此外还有线程的名称、优先级等属性：

```objective-c
@property (nullable, copy) NSString *name;
@property double threadPriority;
```

NSThread中定义了一些方法用于控制线程的状态：

启动线程，使线程从就绪状态转为运行状态，当执行完指定的任务后就会进入死亡状态：

```objective-c
- (void)start;
```

阻塞线程，可以指定时间：

```objective-c
+ (void)sleepUntilDate:(NSDate *)date;
+ (void)sleepForTimeInterval:(NSTimeInterval)ti;
```

强制停止线程，使其进入死亡状态：

```objective-c
+ (void)exit;
```

还有一些方法用于判断线程的当前状态：

判断是否为主线程：

```objective-c
- (BOOL)isMainThread
```

判断线程是否正在执行：

```objective-c
- (void)isExecuting;
```

判断线程是否已结束：

```objective-c
- (void)isFinished;
```

####  线程通信

当需要在多个线程之间进行切换时，就要用到线程通信

在主线程上执行某个方法，参数分别为：要执行的方法、该方法的参数、是否阻塞、Runloop model：

```objective-c
- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait modes:(nullable NSArray<NSString *> *)array;
- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(nullable id)arg waitUntilDone:(BOOL)wait;
```

此外还可以在指定的线程上执行方法：

```objective-c
- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait modes:(NSArray *)array NS_AVAILABLE(10_5, 2_0);
- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait NS_AVAILABLE(10_5, 2_0);
```

#### 线程安全

为了防止多个线程在对同一个数据读写时发生冲突，需要在读写时加锁，IOS中加锁的方法有多种。

- @synchronized

  在代码前加上`@synchronized`可以保证该代码在同一时间内只有一个线程在执行：

  ```objective-c
  @synchronized (self) {
  		// 互斥代码
  }
  ```

- NSLock

  NSLock是一个锁对象，分别使用`lock`和`unlock`方法加锁和解锁。当一个线程请求加锁时，如果当前已经上锁，该线程就会进入阻塞空转，即轮询请求加锁，但当轮询超过1秒后就会进入waiting状态，等到锁可用的时候，该线程就会立刻被唤醒。

  另外还有一个方法是`tryLock`，该方法在不能加锁时不会阻塞，而是继续执行后面的代码。

- 其他常用的方法还有`NSConditionLock`, `NSRecursiveLock`等。