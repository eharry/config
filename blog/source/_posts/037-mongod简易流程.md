---
title: 037-mongod简易流程
date: 2018-02-18 09:33:08
tags: mongodb,
---

任何一个现代数据库,从组件上来分, 都是客户端和服务端, 如果再具体细分服务端, 一般存储引擎都采用插件的方式, 所以服务端又可以细分为 框架和存储引擎实现.



一般来说,框架干的事情都是跟客户端的网络交互等一些共用的特性. 所以一般的数据库二次开发,也都是在框架的基础上做的开发, 比如增强某些限制功能, 给某些用户特权,增加审计功能等.



<!--more-->



MessageHandler 可以说是整个mongodb最核心的消息处理类, 当然当前这个类仅仅定义了一个借口文件,具体实现,需要参考MessageHandler的子类.

```bash
class MessageHandler {
public:
    virtual ~MessageHandler() {}

    /**
     * Called once when a socket is connected.
     */
    virtual void connected(AbstractMessagingPort* p) = 0;

    /**
     * Called every time a message comes in. Handler is responsible for responding to client.
     */
    virtual void process(Message& m, AbstractMessagingPort* p) = 0;

    /**
     * Called once, either when the client disconnects or when the process is shutting down. After
     * close() is called, this handler's AbstractMessagingPort pointer (passed in via the
     * connected() method) is no longer valid.
     */
    virtual void close() = 0;
};
```



在整个mongodb代码中, MessageHandler共有三个子类,分别是

1. MyMessageHandler  位于 db.cpp
2. DummyMessageHandler 位于 Scoped_db_conn_test.cpp
3. ShardedMessageHandler 位于Server.cpp



忽略测代码,上面的1,对应的是smongod的messagehandler, 而3,对应的则是mongos的messagehandler.



先看一下 mongod的messagehandler, 也就是MyMessageHandler  

```bash
class MyMessageHandler : public MessageHandler {
public:
    virtual void connected(AbstractMessagingPort* p) {
        Client::initThread("conn", p);
    }

    virtual void process(Message& m, AbstractMessagingPort* port) {
        while (true) {
            ...
            DbResponse dbresponse;
            {
                auto opCtx = getGlobalServiceContext()->makeOperationContext(&cc());
                assembleResponse(opCtx.get(), m, dbresponse, port->remote());
                ...
            }

            ...
            port->reply(m, dbresponse.response, dbresponse.responseTo);
            break;
        }
    }

    virtual void close() {
        Client::destroy();
    }
};
```

缩减了一些不必要的代码后,可以看出, connected和close函数, 是辅助类函数, 主要的服务响应, 都在process函数里. process, 通过assembleResponse函数,得到命令的返回结果, 并通过port->reply函数进行通讯响应.



MessageServer 定义了mongodb服务器的行为,

```bash
class MessageServer {
public:
    struct Options {
        int port;            // port to bind to
        std::string ipList;  // addresses to bind to

        Options() : port(0), ipList("") {}
    };

    virtual ~MessageServer() {}
    virtual void run() = 0;
    virtual void setAsTimeTracker() = 0;
    virtual bool setupSockets() = 0;
};
```



在整个mongodb的代码中,MessageServer只要一个子类,也就是PortMessageServer.

从函数createServer也可以看出,只要是创建server,基本上就是PortMessageServer.

```bash
MessageServer* createServer(const MessageServer::Options& opts,
                            std::shared_ptr<MessageHandler> handler) {
    return new PortMessageServer(opts, std::move(handler));
}
```





而PortMessageServer的定义如下,我删去了我认为不重要的部分

```c++
class PortMessageServer : public MessageServer, public Listener {
public:
    PortMessageServer(const MessageServer::Options& opts, std::shared_ptr<MessageHandler> handler)
        : Listener("", opts.ipList, opts.port), _handler(std::move(handler)) {}

    virtual void accepted(std::shared_ptr<Socket> psocket, long long connectionId) {
        ...
    }
    ...

    void run() {
        initAndListen();
    }
    ...

private:
    const std::shared_ptr<MessageHandler> _handler;
    static void* handleIncomingMsg(void* arg) {
    }
};
```

首先,这个类PortMessageServer, 不仅仅是MessageServer的子类,也是Listener子类,所以表示它也实现了Listener的一些工作. 



先看构造函数,传入参数很简单, 只有两个

1. MessageServer::Options& opts
2. std::shared_ptr<MessageHandler>



opts,就是两个构成,一个是ipList,表示服务监听的ip列表, 一个是端口.



handleIncomingMsg是静态函数,那么可知, 这个_handlerc成员变量,并不能在这个函数中访问.

肯定是通过arg将所需要的参数一并传入其中.



server.run方法里面,仅仅运行了 initAndListen, 可以猜到这个函数应该具有一个无线循环的loop.



那么下来一块看一下这个 initAndListen 函数, 底下函数是我删去了我认为不重要的部分

```c++
void Listener::initAndListen() {
    ...
    while (!inShutdown()) {
        ...
        maxSelectTime.tv_sec = 0;
        maxSelectTime.tv_usec = 10000;
        const int ret = select(maxfd + 1, fds, NULL, NULL, &maxSelectTime);
        ...
        for (vector<SOCKET>::iterator it = _socks.begin(), end = _socks.end(); it != end; ++it) {
            if (!(FD_ISSET(*it, fds)))
                continue;
            SockAddr from;
            int s = accept(*it, from.raw(), &from.addressSize);
            ...
            std::shared_ptr<Socket> pnewSock(new Socket(s, from));
            ...
            accepted(pnewSock, myConnectionNumber);
        }
    }
}
```

查看简化后的initAndListen, 可见整个函数在while循环中, 只要不是shutdown, 就一直会跑这个循环.

程序会阻塞在select这个函数中, 当有新的连接接入时, 系统会执行 accepted函数. 



从gdb的路径也可以看出,系统确实是停留在了mongo::Listener::initAndListen的select函数上.

```bash
#0  0x00007f9c5c132593 in select () at ../sysdeps/unix/syscall-template.S:84
#1  0x0000000002b8b04e in mongo::Listener::initAndListen (this=0x58d4368) at src/mongo/util/net/listen.cpp:269
#2  0x0000000002b94804 in mongo::PortMessageServer::run (this=0x58d4360) at src/mongo/util/net/message_server_port.cpp:174
#3  0x0000000001f5db8e in mongo::(anonymous namespace)::_initAndListen (listenPort=27017) at src/mongo/db/db.cpp:791
#4  0x0000000001f5e0c2 in mongo::(anonymous namespace)::initAndListen (listenPort=27017) at src/mongo/db/db.cpp:796
#5  0x0000000001f5f588 in mongoDbMain (argc=1, argv=0x7ffe2c890408, envp=0x7ffe2c890418) at src/mongo/db/db.cpp:1032
#6  0x0000000001f5e3fc in main (argc=1, argv=0x7ffe2c890408, envp=0x7ffe2c890418) at src/mongo/db/db.cpp:843
```



注意,这个accepted就是PortMessageServer里面定义一个accepted函数.



accpeted函数如下, 任然是删去了不重要的代码

```c++
virtual void accepted(std::shared_ptr<Socket> psocket, long long connectionId) {
        ScopeGuard sleepAfterClosingPort = MakeGuard(sleepmillis, 2);
        std::unique_ptr<MessagingPortWithHandler> portWithHandler(
            new MessagingPortWithHandler(psocket, _handler, connectionId));

        try {
            pthread_attr_t attrs;
            pthread_attr_init(&attrs);
            pthread_attr_setdetachstate(&attrs, PTHREAD_CREATE_DETACHED);

            static const size_t STACK_SIZE = 1024 * 1024;
            size_t stackSizeToSet = STACK_SIZE;
            pthread_attr_setstacksize(&attrs, stackSizeToSet);

            pthread_t thread;
            int failed = pthread_create(&thread, &attrs, &handleIncomingMsg, portWithHandler.get());

            pthread_attr_destroy(&attrs);

            portWithHandler.release();
            sleepAfterClosingPort.Dismiss();
        } catch (...) {
            ...
        }
    }
```



这个accpeted函数很简单, 

1. 把传入的psocket, connectionId和类成员变量_handler封装到对象 portWithHandler中
2. 创建一个thread, 运行handleIncomingMsg, 传入参数是portWithHandler.



这也就就是了为什么_handler可以在handleIncomingMsg被引用了.



这块,我们可以看到, 代码中对每个thread的堆栈大小,进行了设置 1M. 这也就是每个连接创建时,消耗1m内存的由来. 



再看一下handleIncomingMsg的源代码

```c++
static void* handleIncomingMsg(void* arg) {
        unique_ptr<MessagingPortWithHandler> portWithHandler(
            static_cast<MessagingPortWithHandler*>(arg));
        const std::shared_ptr<MessageHandler> handler = portWithHandler->getHandler();

        setThreadName(std::string(str::stream() << "conn" << portWithHandler->connectionId()));

        Message m;
        int64_t counter = 0;
        try {
            handler->connected(portWithHandler.get());
            ON_BLOCK_EXIT([handler]() { handler->close(); });

            while (!inShutdown()) {
                m.reset();
                portWithHandler->psock->clearCounters();

                if (!portWithHandler->recv(m)) {
                    break;
                }

                handler->process(m, portWithHandler.get());
                networkCounter.hit(portWithHandler->psock->getBytesIn(),
                                   portWithHandler->psock->getBytesOut());

                // Occasionally we want to see if we're using too much memory.
                if ((counter++ & 0xf) == 0) {
                    markThreadIdle();
                }
            }
        }
        catch...
        portWithHandler->shutdown();
    
        return NULL;
    }
};
```

 

研究一个线程, 首先先看他什么时候开始, linux中,当线程被创建出来后,就有可能开始运行了,具体取决于os调度,但可以知道的是,并不需要在父线程再调用一次start命令.



而线程退出的调节,可以看出是portWithHandler->recv返回false的时候, 这个循环退出.



这里具体处理连接事务的,就是前面说的MyMessageHandler, 分别调用了

1. handler->connected(portWithHandler.get());
2. handler->process(m, portWithHandler.get());
3. ON_BLOCK_EXIT([handler]() { handler->close(); });





```c++
void assembleResponse(OperationContext* txn,
                      Message& m,
                      DbResponse& dbresponse,
                      const HostAndPort& remote) {
    DbMessage dbmsg(m);

    Client& c = *txn->getClient();

    const char* ns = dbmsg.messageShouldHaveNs() ? dbmsg.getns() : NULL;
    const NamespaceString nsString = ns ? NamespaceString(ns) : NamespaceString();

    CurOp& currentOp = *CurOp::get(txn);
    {
        stdx::lock_guard<Client> lk(*txn->getClient());
        // Commands handling code will reset this if the operation is a command
        // which is logically a basic CRUD operation like query, insert, etc.
        currentOp.setNetworkOp_inlock(op);
        currentOp.setLogicalOp_inlock(networkOpToLogicalOp(op));
    }

    if (op == dbQuery) {
        if (isCommand) {
            receivedCommand(txn, nsString, c, dbresponse, m);
        } else {
            receivedQuery(txn, nsString, c, dbresponse, m);
        }
    } else if (op == dbCommand) {
        receivedRpc(txn, c, dbresponse, m);
    } else if (op == dbGetMore) {
        if (!receivedGetMore(txn, dbresponse, m, currentOp))
            shouldLogOpDebug = true;
    } else if (op == dbMsg) {
        // deprecated - replaced by commands
        const char* p = dbmsg.getns();

        int len = strlen(p);

        if (strcmp("end", p) == 0)
            dbresponse.response.setData(opReply, "dbMsg end no longer supported");
        else
            dbresponse.response.setData(opReply, "i am fine - dbMsg deprecated");

        dbresponse.responseTo = m.header().getId();
    } else {
        try {
            if (op == dbKillCursors) {
                currentOp.ensureStarted();
                logThreshold = 10;
                receivedKillCursors(txn, m);
            } else if (op != dbInsert && op != dbUpdate && op != dbDelete) {
                shouldLogOpDebug = true;
            } else {
                if (op == dbInsert) {
                    receivedInsert(txn, nsString, m, currentOp);
                } else if (op == dbUpdate) {
                    receivedUpdate(txn, nsString, m, currentOp);
                } else if (op == dbDelete) {
                    receivedDelete(txn, nsString, m, currentOp);
                }
            }
        } catch (const UserException& ue) {
            ...
        }
    }
}
```



可以看出,这个函数就是一个分支函数,根据不同的op,进行不同的处理, 



以receivedCommand为例

```c++
static void receivedCommand(OperationContext* txn,
                            const NamespaceString& nss,
                            Client& client,
                            DbResponse& dbResponse,
                            Message& message) {
    invariant(nss.isCommand());

    const MSGID responseTo = message.header().getId();

    DbMessage dbMessage(message);
    QueryMessage queryMessage(dbMessage);

    CurOp* op = CurOp::get(txn);

    rpc::LegacyReplyBuilder builder{};

    runCommands(txn, request, &builder);

    auto response = builder.done();

    op->debug().responseLength = response.header().dataLen();

    dbResponse.response = std::move(response);
    dbResponse.responseTo = responseTo;
}
```



核心都封装到runCommands里面, 

```c++
void runCommands(OperationContext* txn,
                 const rpc::RequestInterface& request,
                 rpc::ReplyBuilderInterface* replyBuilder) {
    Command::execCommand(txn, c, request, replyBuilder);
}
```





Command::execCommand, 经过一系列的检查后,运行了command->run函数

```c++
void Command::execCommand(OperationContext* txn,
                          Command* command,
                          const rpc::RequestInterface& request,
                          rpc::ReplyBuilderInterface* replyBuilder) {

        rpc::setOperationProtocol(txn, request.getProtocol());  // SERVER-21485.  Remove after 3.2

        dassert(replyBuilder->getState() == rpc::ReplyBuilderInterface::State::kCommandReply);

        std::string dbname = request.getDatabase().toString();
        unique_ptr<MaintenanceModeSetter> mmSetter;


        std::array<BSONElement, std::tuple_size<decltype(neededFieldNames)>::value>
            extractedFields{};
        request.getCommandArgs().getFields(neededFieldNames, &extractedFields);

        ImpersonationSessionGuard guard(txn);

        repl::ReplicationCoordinator* replCoord =
            repl::ReplicationCoordinator::get(txn->getClient()->getServiceContext());
        const bool iAmPrimary = replCoord->canAcceptWritesForDatabase(dbname);

        {
            bool commandCanRunOnSecondary = command->slaveOk();

            bool commandIsOverriddenToRunOnSecondary = command->slaveOverrideOk() &&
                rpc::ServerSelectionMetadata::get(txn).canRunOnSecondary();

            bool iAmStandalone = !txn->writesAreReplicated();
            bool canRunHere = iAmPrimary || commandCanRunOnSecondary ||
                commandIsOverriddenToRunOnSecondary || iAmStandalone;

            // This logic is clearer if we don't have to invert it.
            if (!canRunHere && command->slaveOverrideOk()) {
                uasserted(ErrorCodes::NotMasterNoSlaveOk, "not master and slaveOk=false");
            }
        }

        if (command->maintenanceMode()) {
            mmSetter.reset(new MaintenanceModeSetter);
        }

        if (command->shouldAffectCommandCounter()) {
            OpCounters* opCounters = &globalOpCounters;
            opCounters->gotCommand();
        }

        // Handle command option maxTimeMS.
        int maxTimeMS = uassertStatusOK(
            LiteParsedQuery::parseMaxTimeMS(extractedFields[kCmdOptionMaxTimeMSField]));

        CurOp::get(txn)->setMaxTimeMicros(static_cast<unsigned long long>(maxTimeMS) * 1000);

        // Operations are only versioned against the primary. We also make sure not to redo shard
        // version handling if this command was issued via the direct client.
        if (iAmPrimary && !txn->getClient()->isInDirectClient()) {
            // Handle shard version and config optime information that may have been sent along with
            // the command.
            auto& operationShardVersion = OperationShardVersion::get(txn);

            auto commandNS = NamespaceString(command->parseNs(dbname, request.getCommandArgs()));
            operationShardVersion.initializeFromCommand(commandNS,
                                                        extractedFields[kShardVersionField]);
        }

        // Can throw
        txn->checkForInterrupt();  // May trigger maxTimeAlwaysTimeOut fail point.

        bool retval = false;

        CurOp::get(txn)->ensureStarted();

        command->_commandsExecuted.increment();

        retval = command->run(txn, request, replyBuilder);

        if (!retval) {
            command->_commandsFailed.increment();
        }
}
```





Command 是整个mongodb 命令的基类, 他定义了所有mongodb command的基本属性,

这个类太重要了,以致于它的代码.我一行不删的贴出来. 

```c++
/** mongodb "commands" (sent via db.$cmd.findOne(...))
    subclass to make a command.  define a singleton object for it.
    */
class Command {
protected:
    // The type of the first field in 'cmdObj' must be mongo::String. The first field is
    // interpreted as a collection name.
    std::string parseNsFullyQualified(const std::string& dbname, const BSONObj& cmdObj) const;

    // The type of the first field in 'cmdObj' must be mongo::String or Symbol.
    // The first field is interpreted as a collection name.
    std::string parseNsCollectionRequired(const std::string& dbname, const BSONObj& cmdObj) const;

public:
    typedef StringMap<Command*> CommandMap;

    // NOTE: Do not remove this declaration, or relocate it in this class. We
    // are using this method to control where the vtable is emitted.
    virtual ~Command();

    // Return the namespace for the command. If the first field in 'cmdObj' is of type
    // mongo::String, then that field is interpreted as the collection name, and is
    // appended to 'dbname' after a '.' character. If the first field is not of type
    // mongo::String, then 'dbname' is returned unmodified.
    virtual std::string parseNs(const std::string& dbname, const BSONObj& cmdObj) const;

    // Utility that returns a ResourcePattern for the namespace returned from
    // parseNs(dbname, cmdObj).  This will be either an exact namespace resource pattern
    // or a database resource pattern, depending on whether parseNs returns a fully qualifed
    // collection name or just a database name.
    ResourcePattern parseResourcePattern(const std::string& dbname, const BSONObj& cmdObj) const;

    virtual std::size_t reserveBytesForReply() const {
        return 0u;
    }

    const std::string name;

    /* run the given command
       implement this...

       return value is true if succeeded.  if false, set errmsg text.
    */
    virtual bool run(OperationContext* txn,
                     const std::string& db,
                     BSONObj& cmdObj,
                     int options,
                     std::string& errmsg,
                     BSONObjBuilder& result) = 0;

    /**
     * Translation point between the new request/response types and the legacy types.
     *
     * Then we won't need to mutate the command object. At that point we can also make
     * this method virtual so commands can override it directly.
     */
    /*virtual*/ bool run(OperationContext* txn,
                         const rpc::RequestInterface& request,
                         rpc::ReplyBuilderInterface* replyBuilder);


    /**
     * This designation for the command is only used by the 'help' call and has nothing to do
     * with lock acquisition. The reason we need to have it there is because
     * SyncClusterConnection uses this to determine whether the command is update and needs to
     * be sent to all three servers or just one.
     *
     * Eventually when SyncClusterConnection is refactored out, we can get rid of it.
     */
    virtual bool isWriteCommandForConfigServer() const = 0;

    /* Return true if only the admin ns has privileges to run this command. */
    virtual bool adminOnly() const {
        return false;
    }

    void htmlHelp(std::stringstream&) const;

    /* Like adminOnly, but even stricter: we must either be authenticated for admin db,
       or, if running without auth, on the local interface.  Used for things which
       are so major that remote invocation may not make sense (e.g., shutdownServer).

       When localHostOnlyIfNoAuth() is true, adminOnly() must also be true.
    */
    virtual bool localHostOnlyIfNoAuth(const BSONObj& cmdObj) {
        return false;
    }

    /* Return true if slaves are allowed to execute the command
    */
    virtual bool slaveOk() const = 0;

    /* Return true if the client force a command to be run on a slave by
       turning on the 'slaveOk' option in the command query.
    */
    virtual bool slaveOverrideOk() const {
        return false;
    }

    /**
     * Override and return fales if the command opcounters should not be incremented on
     * behalf of this command.
     */
    virtual bool shouldAffectCommandCounter() const {
        return true;
    }

    virtual void help(std::stringstream& help) const;

    /**
     * Commands which can be explained override this method. Any operation which has a query
     * part and executes as a tree of execution stages can be explained. A command should
     * implement explain by:
     *
     *   1) Calling its custom parse function in order to parse the command. The output of
     *   this function should be a CanonicalQuery (representing the query part of the
     *   operation), and a PlanExecutor which wraps the tree of execution stages.
     *
     *   2) Calling Explain::explainStages(...) on the PlanExecutor. This is the function
     *   which knows how to convert an execution stage tree into explain output.
     *
     * TODO: Remove the 'serverSelectionMetadata' parameter in favor of reading the
     * ServerSelectionMetadata off 'txn'. Once OP_COMMAND is implemented in mongos, this metadata
     * will be parsed and attached as a decoration on the OperationContext, as is already done on
     * the mongod side.
     */
    virtual Status explain(OperationContext* txn,
                           const std::string& dbname,
                           const BSONObj& cmdObj,
                           ExplainCommon::Verbosity verbosity,
                           const rpc::ServerSelectionMetadata& serverSelectionMetadata,
                           BSONObjBuilder* out) const {
        return Status(ErrorCodes::IllegalOperation, "Cannot explain cmd: " + name);
    }

    /**
     * Checks if the client associated with the given OperationContext, "txn", is authorized to run
     * this command on database "dbname" with the invocation described by "cmdObj".
     */
    virtual Status checkAuthForOperation(OperationContext* txn,
                                         const std::string& dbname,
                                         const BSONObj& cmdObj);

    /**
     * Redacts "cmdObj" in-place to a form suitable for writing to logs.
     *
     * The default implementation does nothing.
     */
    virtual void redactForLogging(mutablebson::Document* cmdObj);

    /**
     * Returns a copy of "cmdObj" in a form suitable for writing to logs.
     * Uses redactForLogging() to transform "cmdObj".
     */
    BSONObj getRedactedCopyForLogging(const BSONObj& cmdObj);

    /* Return true if a replica set secondary should go into "recovering"
       (unreadable) state while running this command.
     */
    virtual bool maintenanceMode() const {
        return false;
    }

    /* Return true if command should be permitted when a replica set secondary is in "recovering"
       (unreadable) state.
     */
    virtual bool maintenanceOk() const {
        return true; /* assumed true prior to commit */
    }

    /**
     * Returns true if this Command supports the readConcern argument.
     *
     * If the readConcern argument is sent to a command that returns false the command processor
     * will reject the command, returning an appropriate error message. For commands that support
     * the argument, the command processor will instruct the RecoveryUnit to only return
     * "committed" data, failing if this isn't supported by the storage engine.
     *
     * Note that this is never called on mongos. Sharded commands are responsible for forwarding
     * the option to the shards as needed. We rely on the shards to fail the commands in the
     * cases where it isn't supported.
     */
    virtual bool supportsReadConcern() const {
        return false;
    }

    virtual LogicalOp getLogicalOp() const {
        return LogicalOp::opCommand;
    }

    /** @param webUI expose the command in the web ui as localhost:28017/<name>
        @param oldName an optional old, deprecated name for the command
    */
    Command(StringData _name, bool webUI = false, StringData oldName = StringData());

protected:
    BSONObj getQuery(const BSONObj& cmdObj) {
        if (cmdObj["query"].type() == Object)
            return cmdObj["query"].embeddedObject();
        if (cmdObj["q"].type() == Object)
            return cmdObj["q"].embeddedObject();
        return BSONObj();
    }

    static void logIfSlow(const Timer& cmdTimer, const std::string& msg);

    static CommandMap* _commands;
    static CommandMap* _commandsByBestName;
    static CommandMap* _webCommands;

    // Counters for how many times this command has been executed and failed
    Counter64 _commandsExecuted;
    Counter64 _commandsFailed;

    // Pointers to hold the metrics tree references
    ServerStatusMetricField<Counter64> _commandsExecutedMetric;
    ServerStatusMetricField<Counter64> _commandsFailedMetric;

public:
    static const CommandMap* commandsByBestName() {
        return _commandsByBestName;
    }
    static const CommandMap* webCommands() {
        return _webCommands;
    }

    // Counter for unknown commands
    static Counter64 unknownCommands;

    static void runAgainstRegistered(OperationContext* txn,
                                     const char* ns,
                                     BSONObj& jsobj,
                                     BSONObjBuilder& anObjBuilder,
                                     int queryOptions = 0);
    static Command* findCommand(StringData name);

    /**
     * Executes a command after stripping metadata, performing authorization checks,
     * handling audit impersonation, and (potentially) setting maintenance mode. This method
     * also checks that the command is permissible to run on the node given its current
     * replication state. All the logic here is independent of any particular command; any
     * functionality relevant to a specific command should be confined to its run() method.
     *
     * This is currently used by mongod and dbwebserver.
     */
    static void execCommand(OperationContext* txn,
                            Command* command,
                            const rpc::RequestInterface& request,
                            rpc::ReplyBuilderInterface* replyBuilder);

    // For mongos
    // TODO: remove this entirely now that all instances of ClientBasic are instances
    // of Client. This will happen as part of SERVER-18292
    static void execCommandClientBasic(OperationContext* txn,
                                       Command* c,
                                       ClientBasic& client,
                                       int queryOptions,
                                       const char* ns,
                                       BSONObj& cmdObj,
                                       BSONObjBuilder& result);

    // Helper for setting errmsg and ok field in command result object.
    static void appendCommandStatus(BSONObjBuilder& result, bool ok, const std::string& errmsg);

    // @return s.isOK()
    static bool appendCommandStatus(BSONObjBuilder& result, const Status& status);

    // Converts "result" into a Status object.  The input is expected to be the object returned
    // by running a command.  Returns ErrorCodes::CommandResultSchemaViolation if "result" does
    // not look like the result of a command.
    static Status getStatusFromCommandResult(const BSONObj& result);

    /**
     * Parses cursor options from the command request object "cmdObj".  Used by commands that
     * take cursor options.  The only cursor option currently supported is "cursor.batchSize".
     *
     * If a valid batch size was specified, returns Status::OK() and fills in "batchSize" with
     * the specified value.  If no batch size was specified, returns Status::OK() and fills in
     * "batchSize" with the provided default value.
     *
     * If an error occurred while parsing, returns an error Status.  If this is the case, the
     * value pointed to by "batchSize" is unspecified.
     */
    static Status parseCommandCursorOptions(const BSONObj& cmdObj,
                                            long long defaultBatchSize,
                                            long long* batchSize);

    /**
     * Helper for setting a writeConcernError field in the command result object if
     * a writeConcern error occurs.
     */
    static void appendCommandWCStatus(BSONObjBuilder& result, const Status& status);

    /**
     * If true, then testing commands are available. Defaults to false.
     *
     * Testing commands should conditionally register themselves by consulting this flag:
     *
     *     MONGO_INITIALIZER(RegisterMyTestCommand)(InitializerContext* context) {
     *         if (Command::testCommandsEnabled) {
     *             // Leaked intentionally: a Command registers itself when constructed.
     *             new MyTestCommand();
     *         }
     *         return Status::OK();
     *     }
     *
     * To make testing commands available by default, change the value to true before running any
     * mongo initializers:
     *
     *     int myMain(int argc, char** argv, char** envp) {
     *         static StaticObserver StaticObserver;
     *         Command::testCommandsEnabled = true;
     *         ...
     *         runGlobalInitializersOrDie(argc, argv, envp);
     *         ...
     *     }
     */
    static bool testCommandsEnabled;

    /**
     * Returns true if this a request for the 'help' information associated with the command.
     */
    static bool isHelpRequest(const BSONElement& helpElem);

    static const char kHelpFieldName[];

    /**
     * Generates a reply from the 'help' information associated with a command. The state of
     * the passed ReplyBuilder will be in kOutputDocs after calling this method.
     */
    static void generateHelpResponse(OperationContext* txn,
                                     const rpc::RequestInterface& request,
                                     rpc::ReplyBuilderInterface* replyBuilder,
                                     const Command& command);

    /**
     * When an assertion is hit during command execution, this method is used to fill the fields
     * of the command reply with the information from the error. In addition, information about
     * the command is logged. This function does not return anything, because there is typically
     * already an active exception when this function is called, so there
     * is little that can be done if it fails.
     */
    static void generateErrorResponse(OperationContext* txn,
                                      rpc::ReplyBuilderInterface* replyBuilder,
                                      const DBException& exception,
                                      const rpc::RequestInterface& request,
                                      Command* command,
                                      const BSONObj& metadata);

    /**
     * Generates a command error response. This overload of generateErrorResponse is intended
     * to be called if the command is successfully parsed, but there is an error before we have
     * a handle to the actual Command object. This can happen, for example, when the command
     * is not found.
     */
    static void generateErrorResponse(OperationContext* txn,
                                      rpc::ReplyBuilderInterface* replyBuilder,
                                      const DBException& exception,
                                      const rpc::RequestInterface& request);

    /**
     * Generates a command error response. Similar to other overloads of generateErrorResponse,
     * but doesn't print any information about the specific command being executed. This is
     * neccessary, for example, if there is
     * an assertion hit while parsing the command.
     */
    static void generateErrorResponse(OperationContext* txn,
                                      rpc::ReplyBuilderInterface* replyBuilder,
                                      const DBException& exception);

    /**
     * Records the error on to the OperationContext. This hook is needed because mongos
     * does not have CurOp linked in to it.
     */
    static void registerError(OperationContext* txn, const DBException& exception);

    /**
     * Checks to see if the client executing "txn" is authorized to run the given command with the
     * given parameters on the given named database.
     *
     * Returns Status::OK() if the command is authorized.  Most likely returns
     * ErrorCodes::Unauthorized otherwise, but any return other than Status::OK implies not
     * authorized.
     */
    static Status checkAuthorization(Command* c,
                                     OperationContext* client,
                                     const std::string& dbname,
                                     const BSONObj& cmdObj);

private:
    /**
     * Checks if the given client is authorized to run this command on database "dbname"
     * with the invocation described by "cmdObj".
     *
     * NOTE: Implement checkAuthForOperation that takes an OperationContext* instead.
     */
    virtual Status checkAuthForCommand(ClientBasic* client,
                                       const std::string& dbname,
                                       const BSONObj& cmdObj);
    /**
     * Appends to "*out" the privileges required to run this command on database "dbname" with
     * the invocation described by "cmdObj".  New commands shouldn't implement this, they should
     * implement checkAuthForCommand instead.
     */
    virtual void addRequiredPrivileges(const std::string& dbname,
                                       const BSONObj& cmdObj,
                                       std::vector<Privilege>* out) {
        // The default implementation of addRequiredPrivileges should never be hit.
        fassertFailed(16940);
    }
};
```

