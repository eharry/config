###mongodb 代码阅读-003

####mongodb util类之Decorable



在阅读mongodb源代码的时候,经常会碰到这样的函数,   以CmdCreateUser run方法为例,

```c++
...

ServiceContext* serviceContext = txn->getClient()->getServiceContext();
AuthorizationManager* authzManager = AuthorizationManager::get(serviceContext);
```

上面的函数 AuthorizationManager* authzManager = AuthorizationManager::get(serviceContext);

一看就是一个静态函数,  AuthorizationManager 可以根据 serviceContext 得到一个AuthorizationManager的对象.



如果不仔细研究代码,凭借以往经验猜想的话

这个函数最基本的实现,肯定是AuthorizationManager里面有一个静态map(或者是别的什么容器), 这个容器里包含了 serviceContext 和 AuthorizationManager的对应关系. 这样才能根据 serviceContext得到AuthorizationManager对象.



但是,如果再仔细阅读以下AuthorizationManager的代码的话,你就会发现, AuthorizationManager类中,并没有所谓的静态容器来保存AuthorizationManager和serviceContext的对应关系.  甚至连保存serviceContext的map都没有.



一般来说,AuthorizationManager和serviceContext的对应关系, 要么存在AuthorizationManager上,要么存在serviceContext上. 既然AuthorizationManager没有,那么很有可能是在serviceContext上.



serviceContext的定义如下:

```c++
class ServiceContext : public Decorable<ServiceContext> {
    MONGO_DISALLOW_COPYING(ServiceContext);

public:
    /**
     * Special deleter used for cleaning up Client objects owned by a ServiceContext.
     * See UniqueClient, below.
     */
    class ClientDeleter {
    public:
        void operator()(Client* client) const;
    };

    /**
     * Observer interface implemented to hook client and operation context creation and
     * destruction.
     */
    class ClientObserver {
    public:
        virtual ~ClientObserver() = default;

        /**
         * Hook called after a new client "client" is created on a service by
         * service->makeClient().
         *
         * For a given client and registered instance of ClientObserver, if onCreateClient
         * returns without throwing an exception, onDestroyClient will be called when "client"
         * is deleted.
         */
        virtual void onCreateClient(Client* client) = 0;

        /**
         * Hook called on a "client" created by a service before deleting "client".
         *
         * Like a destructor, must not throw exceptions.
         */
        virtual void onDestroyClient(Client* client) = 0;

        /**
         * Hook called after a new operation context is created on a client by
         * service->makeOperationContext(client)  or client->makeOperationContext().
         *
         * For a given operation context and registered instance of ClientObserver, if
         * onCreateOperationContext returns without throwing an exception,
         * onDestroyOperationContext will be called when "opCtx" is deleted.
         */
        virtual void onCreateOperationContext(OperationContext* opCtx) = 0;

        /**
         * Hook called on a "opCtx" created by a service before deleting "opCtx".
         *
         * Like a destructor, must not throw exceptions.
         */
        virtual void onDestroyOperationContext(OperationContext* opCtx) = 0;
    };

    using ClientSet = unordered_set<Client*>;

    /**
     * Cursor for enumerating the live Client objects belonging to a ServiceContext.
     *
     * Lifetimes of this type are synchronized with client creation and destruction.
     */
    class LockedClientsCursor {
    public:
        /**
         * Constructs a cursor for enumerating the clients of "service", blocking "service" from
         * creating or destroying Client objects until this instance is destroyed.
         */
        explicit LockedClientsCursor(ServiceContext* service);

        /**
         * Returns the next client in the enumeration, or nullptr if there are no more clients.
         */
        Client* next();

    private:
        stdx::unique_lock<stdx::mutex> _lock;
        ClientSet::const_iterator _curr;
        ClientSet::const_iterator _end;
    };

    /**
     * Special deleter used for cleaning up OperationContext objects owned by a ServiceContext.
     * See UniqueOperationContext, below.
     */
    class OperationContextDeleter {
    public:
        void operator()(OperationContext* opCtx) const;
    };

    /**
     * This is the unique handle type for Clients created by a ServiceContext.
     */
    using UniqueClient = std::unique_ptr<Client, ClientDeleter>;

    /**
     * This is the unique handle type for OperationContexts created by a ServiceContext.
     */
    using UniqueOperationContext = std::unique_ptr<OperationContext, OperationContextDeleter>;

    virtual ~ServiceContext();

    /**
     * Registers an observer of lifecycle events on Clients created by this ServiceContext.
     *
     * See the ClientObserver type, above, for details.
     *
     * All calls to registerClientObserver must complete before ServiceContext
     * is used in multi-threaded operation, or is used to create clients via calls
     * to makeClient.
     */
    void registerClientObserver(std::unique_ptr<ClientObserver> observer);

    /**
     * Creates a new Client object representing a client session associated with this
     * ServiceContext.
     *
     * The "desc" string is used to set a descriptive name for the client, used in logging.
     *
     * If supplied, "p" is the communication channel used for communicating with the client.
     */
    UniqueClient makeClient(std::string desc, AbstractMessagingPort* p = nullptr);

    /**
     * Creates a new OperationContext on "client".
     *
     * "client" must not have an active operation context.
     */
    UniqueOperationContext makeOperationContext(Client* client);

    //
    // Storage
    //

    /**
     * Register a storage engine.  Called from a MONGO_INIT that depends on initializiation of
     * the global environment.
     * Ownership of 'factory' is transferred to global environment upon registration.
     */
    virtual void registerStorageEngine(const std::string& name,
                                       const StorageEngine::Factory* factory) = 0;

    /**
     * Returns true if "name" refers to a registered storage engine.
     */
    virtual bool isRegisteredStorageEngine(const std::string& name) = 0;

    /**
     * Produce an iterator over all registered storage engine factories.
     * Caller owns the returned object and is responsible for deleting when finished.
     *
     * Never returns nullptr.
     */
    virtual StorageFactoriesIterator* makeStorageFactoriesIterator() = 0;

    virtual void initializeGlobalStorageEngine() = 0;

    /**
     * Shuts down storage engine cleanly and releases any locks on mongod.lock.
     */
    virtual void shutdownGlobalStorageEngineCleanly() = 0;

    /**
     * Return the storage engine instance we're using.
     */
    virtual StorageEngine* getGlobalStorageEngine() = 0;

    //
    // Global operation management.  This may not belong here and there may be too many methods
    // here.
    //

    /**
     * Signal all OperationContext(s) that they have been killed.
     */
    virtual void setKillAllOperations() = 0;

    /**
     * Reset the operation kill state after a killAllOperations.
     * Used for testing.
     */
    virtual void unsetKillAllOperations() = 0;

    /**
     * Get the state for killing all operations.
     */
    virtual bool getKillAllOperations() = 0;

    /**
     * Kills the operation "txn" with the code "killCode", if txn has not already been killed.
     * Caller must own the lock on txn->getClient, and txn->getServiceContext() must be the same as
     * this service context.
     **/
    virtual void killOperation(OperationContext* txn,
                               ErrorCodes::Error killCode = ErrorCodes::Interrupted) = 0;

    /**
     * Kills all operations that have a Client that is associated with an incoming user
     * connection, except for the one associated with txn.
     */
    virtual void killAllUserOperations(const OperationContext* txn, ErrorCodes::Error killCode) = 0;

    /**
     * Registers a listener to be notified each time an op is killed.
     *
     * listener does not become owned by the environment. As there is currently no way to
     * unregister, the listener object must outlive this ServiceContext object.
     */
    virtual void registerKillOpListener(KillOpListenerInterface* listener) = 0;

    //
    // Global OpObserver.
    //

    /**
     * Set the OpObserver.
     */
    virtual void setOpObserver(std::unique_ptr<OpObserver> opObserver) = 0;

    /**
     * Return the OpObserver instance we're using.
     */
    virtual OpObserver* getOpObserver() = 0;

    /**
     * Returns the tick/clock source set in this context.
     */
    TickSource* getTickSource() const;
    ClockSource* getClockSource() const;

    /**
     * Replaces the current tick/clock source with a new one. In other words, the old source will be
     * destroyed. So make sure that no one is using the old source when calling this.
     */
    void setTickSource(std::unique_ptr<TickSource> newSource);
    void setClockSource(std::unique_ptr<ClockSource> newSource);

protected:
    ServiceContext() = default;

    /**
     * Mutex used to synchronize access to mutable state of this ServiceContext instance,
     * including possibly by its subclasses.
     */
    stdx::mutex _mutex;

private:
    /**
     * Returns a new OperationContext. Private, for use by makeOperationContext.
     */
    virtual std::unique_ptr<OperationContext> _newOpCtx(Client* client) = 0;

    /**
     * Vector of registered observers.
     */
    std::vector<std::unique_ptr<ClientObserver>> _clientObservers;
    ClientSet _clients;

    std::unique_ptr<TickSource> _tickSource;
    std::unique_ptr<ClockSource> _clockSource;
};
```



仔细搜寻代码后,并没有AuthorizationManager的存储变量,  如果再仔细看一下serviceContext的类定义文件的话,发现连AuthorizationManager的class都没有声明. 那么自然不可能存储AuthorizationManager的容器了.



那么这个对应关系到底存在哪呢?



所以,我们的代码分析结果还是应该返回到  AuthorizationManager::get(serviceContext); 这个函数调用上,究竟这个函数是如何工作的?



搜索这个函数的定义, 找到这个函数真正的实现地方

```c++
AuthorizationManager* AuthorizationManager::get(ServiceContext* service) {
    return getAuthorizationManager(service).get();
}
```



不用管 最后一个get, 直接看这个函数getAuthorizationManager



```c++
const auto getAuthorizationManager =
    ServiceContext::declareDecoration<std::unique_ptr<AuthorizationManager>>();
```



然后你就会得到一个这个东西, 看着调用的地方像是个函数啊, 可以看看赋值的地方,这就是个变量啊.

ServiceContext::declareDecoration 的函数定义如下:

```
template <typename T>
static Decoration<T> declareDecoration() {
    return Decoration<T>(getRegistry()->declareDecoration<T>());
}
```

如果这个时候,你继续跟随这个东西分析下去, 十有八九都会被这段复杂的代码逻辑绕晕.



所以我们先不要分析代码细节,研究一下这个赋值和调用的地方

```c++
AuthorizationManager* authzManager = AuthorizationManager::get(serviceContext);
```



```c++
const auto getAuthorizationManager =
    ServiceContext::declareDecoration<std::unique_ptr<AuthorizationManager>>();
```



首先我们看到getAuthorizationManager的参数, 是一个ServiceContext,在赋值的语句里, 它作为对象出现在赋值语句右侧. 正式调用了ServiceContext的这个特定方法,才得到了getAuthorizationManager这个变量.

其次我们看到AuthorizationManager这个类型,作为赋值语句的函数参数, 出现在赋值语句的右侧. 

正式ServiceContext和AuthorizationManager这两个类的配合,才得到了getAuthorizationManager这个变量.



所以我们可以简单的得到一个结论 :

```c++
c=a::declareDecoration<std::unique_ptr<b>>();

b obj = c(a);
```

但是这个赋值语句究竟是现有的a,b之间的关系,才可以运行赋值语句,还是说 这个赋值语句自带了定义规则的属性,这个就不得而知了.



这个时候: Decoration 这个单词可以说明这一切.

装饰, 在这里表示装饰模式.  而装饰模式, 就是指不改变类的情况下,通过装饰类来完成原生类的一些功能和行为的改变.



所以 ServiceContext 和 AuthorizationManager, 这两个必然有一个是装饰类, 而另一个是要被装饰的对象. 

查看各自类代码可知, ServiceContext 继承了 class ServiceContext : public Decorable<ServiceContext> 



ServiceContext的所有装饰行为都被封装到Decorable, 包括ServiceContext跟AuthorizationManager的对应关系.

这样,当得到ServiceContext对象的时候,我们可以从他的父类里,拿到AuthorizationManager的对象,这样就可以得到对应关系了.



注 : 为什么使用装饰模式.

1. 一般来说, ServiceContext和AuthorizationManager的对应关系,一般应该封存在某个类的静态方法里, 这样代码便于理解和维护.但是在某些情况下, 这种方式不好做到. 最主要是就是类之间的依赖关系.

   a. 在上面那个例子中, 如果把AuthorizationManager放到ServiceContext里面, 不可避免要让ServiceContext依赖AuthorizationManager,这样在代码结构上就造成了底层依赖上层的编译逻辑.

   b. 不仅仅是AuthorizationManager依赖ServiceContext, 还有其他的变量,都会依赖ServiceContext, 每新增加一个依赖,都需要重新编译ServiceContext, 这样的软件架构也是不好的.

   c. 代码重复, 同样的依赖代码要写很多相似的代码.

2. 所以一般基于上面说的逻辑,当软件中出现大规模这种结构依赖的时候, 装饰模式是一种比较好的做法. 将类的行为和依赖行为分开到不同类里面执行. 并且将依赖行为抽象化, 不用每个依赖像都重写一个函数.



简单装饰模式的实现:

   1) 将依赖类, 注入到装饰模式里面, 因为依赖的是对象, 需要在装饰模式里面定义一个list,里面存储着所有的依赖对象. 这样当装饰模式创建后,可以通过注册函数将对象注入进来,得到一个装饰模式对象. 然后在其他地方调用相关函数,得到对应关系.

   2) 上述模式将对象注入到装饰类,但是在某些情况下,我们并不能确定调用关系和注入关系的顺序. 或者说装饰类对象生成和注册之间的执行顺序, 所以在此基础之上, 我们将依赖类的构造函数注入到装饰类中. 这样当装饰类进行初始化的时候,可以直接调用构造函数初始化依赖类,这样就免去了注入对象的过程. 仅仅需要注入构造函数即可.

   3)  注入构造函数,按照c++的特性,自然是要构造析构函数了. 

   4)  有了构造和析构函数,考虑到装饰类并不仅仅只保存一个依赖类, 所以为了方便程序其他地方对依赖类的操作,我们应该提供一个方便得到依赖类的对象. 所以可以提供一个map <string, obj>



如果想明白了简单装饰器的实现,那么再看mongodb这块的装饰模式实现,就不会觉得那么难以理解了.



mongodb认为,你注入了这个依赖类规则,肯定是要使用的, 所以讲简单装饰器模式的第二步和第四步合并,在注入依赖规则的同时,返回了一个变量,然后又重定义了(), 只要利用这个变量加上装饰类,就可以得到依赖类的对象. 让调用看上去更像一个函数.



```c++
AuthorizationManager* authzManager = AuthorizationManager::get(serviceContext);
```



```c++
const auto getAuthorizationManager =
    ServiceContext::declareDecoration<std::unique_ptr<AuthorizationManager>>();
```



Decorable内部,并没有实现我说的通过map来保存 类名和对象的结构,而是通过 offset来给出对象地址. mongodb通过每个对象的大小,对其情况等等,计算出依赖类的地址,然后返回给客户.





最后  :   

1. 当看到以下代码时,可以理解为, ServiceContext创建了一个std::unique_ptr<AuthorizationManager>, 我们可以通过getAuthorizationManager(serviceContext)去得到它.

```c++
const auto getAuthorizationManager =
    ServiceContext::declareDecoration<std::unique_ptr<AuthorizationManager>>();
```

2. ServiceContext包含的东西,远不止代码中所显示的那么多, 或者说,主要包含的东西,都已经在装饰器内部被封装为object和一串offset了,要想知道 ServiceContext, 还是应该搜索 ServiceContext::declareDecoration函数的调用情况.
3. 装饰器就是动态添加一些功能行为到原生类里面, 本文主要说了构造函数和析构函数,但可以添加的远不止这些.







