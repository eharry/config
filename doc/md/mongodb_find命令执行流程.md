mongodb find命令执行流程



简介：

程序运行结果如下， 本文从代码级别走一遍 mongodb的查询流程。

注意： 本文分析的是 mongodb 3.6.3的代码，其中实现跟3.2不相同。 阅读本文，请参照3.6.3的代码。

```bash
> db.test1.find()
{ "_id" : "id_1", "v" : "v_1" }
```



服务端对用户的程序相应，在mongo::ServiceEntryPointMongod::handleRequest函数处运行。

```bash
DbResponse ServiceEntryPointMongod::handleRequest(OperationContext* opCtx, const Message& m) {
    // before we lock...
    NetworkOp op = m.operation();
    bool isCommand = false;

    DbMessage dbmsg(m);

    Client& c = *opCtx->getClient();
    if (c.isInDirectClient()) {
        invariant(!opCtx->lockState()->inAWriteUnitOfWork());
    } else {
        LastError::get(c).startRequest();
        AuthorizationSession::get(c)->startRequest(opCtx);

        // We should not be holding any locks at this point
        invariant(!opCtx->lockState()->isLocked());
    }
    ...
```



* 程序首先得到 m.operation(),  这个函数是Message 类自带的函数， 主要是返回这个message的操作类型
* NetworkOp 实际上就是一个int32的枚举类型， 用于约定一些client和server之间的操作类型

```c++
enum NetworkOp : int32_t {
    opInvalid = 0,
    opReply = 1,     /* reply. responseTo is set. */
    dbUpdate = 2001, /* update object */
    dbInsert = 2002,
    // dbGetByOID = 2003,
    dbQuery = 2004,
    dbGetMore = 2005,
    dbDelete = 2006,
    dbKillCursors = 2007,
    // dbCommand_DEPRECATED = 2008, //
    // dbCommandReply_DEPRECATED = 2009, //
    dbCommand = 2010,
    dbCommandReply = 2011,
    dbCompressed = 2012,
    dbMsg = 2013,
};
```

* db.test1.find() 函数的操作类型为 是 'dbMsg'
* 然后程序使用Message对象构建dbmsg， ServiceEntryPointMongod::handleRequest后续程序片段如下

```c++
    CurOp& currentOp = *CurOp::get(opCtx);
    {
        stdx::lock_guard<Client> lk(*opCtx->getClient());
        // Commands handling code will reset this if the operation is a command
        // which is logically a basic CRUD operation like query, insert, etc.
        currentOp.setNetworkOp_inlock(op);
        currentOp.setLogicalOp_inlock(networkOpToLogicalOp(op));
    }

    OpDebug& debug = currentOp.debug();

    long long logThresholdMs = serverGlobalParams.slowMS;
    bool shouldLogOpDebug = shouldLog(logger::LogSeverity::Debug(1));
```

* 上面这段，是一些锁检查和变量设置, ServiceEntryPointMongod::handleRequest后续程序片段如下

```c++

    DbResponse dbresponse;
    if (op == dbMsg || op == dbCommand || (op == dbQuery && isCommand)) {
        dbresponse = runCommands(opCtx, m);
    } else if (op == dbQuery) {
        invariant(!isCommand);
        dbresponse = receivedQuery(opCtx, nsString, c, m);
    } else if (op == dbGetMore) {
        dbresponse = receivedGetMore(opCtx, m, currentOp, &shouldLogOpDebug);
    } else {
        // The remaining operations do not return any response. They are fire-and-forget.
        try {
            if (op == dbKillCursors) {
                currentOp.ensureStarted();
                logThresholdMs = 10;
                receivedKillCursors(opCtx, m);
            } else if (op != dbInsert && op != dbUpdate && op != dbDelete) {
                log() << "    operation isn't supported: " << static_cast<int>(op);
                currentOp.done();
                shouldLogOpDebug = true;
            } else {
                if (!opCtx->getClient()->isInDirectClient()) {
                    uassert(18663,
                            str::stream() << "legacy writeOps not longer supported for "
                                          << "versioned connections, ns: "
                                          << nsString.ns()
                                          << ", op: "
                                          << networkOpToString(op),
                            !ShardedConnectionInfo::get(&c, false));
                }

                if (!nsString.isValid()) {
                    uassert(16257, str::stream() << "Invalid ns [" << ns << "]", false);
                } else if (op == dbInsert) {
                    receivedInsert(opCtx, nsString, m);
                } else if (op == dbUpdate) {
                    receivedUpdate(opCtx, nsString, m);
                } else if (op == dbDelete) {
                    receivedDelete(opCtx, nsString, m);
                } else {
                    invariant(false);
                }
            }
        } catch (const AssertionException& ue) {
            LastError::get(c).setLastError(ue.code(), ue.reason());
            LOG(3) << " Caught Assertion in " << networkOpToString(op) << ", continuing "
                   << redact(ue);
            debug.exceptionInfo = ue.toStatus();
        }
    }
```

* DbResponse dbresponse 就是server给程序返回的信息， server首先构造出一个dbresponse出来，
* 然后根据不同的op，进入不同的函数处理，上面说过，此时的op是dbMsg， 所以进入runCommands函数。
* runCommands 函数如下

```c++
DbResponse runCommands(OperationContext* opCtx, const Message& message) {
    auto replyBuilder = rpc::makeReplyBuilder(rpc::protocolForMessage(message));
    [&] {
        OpMsgRequest request;
        try {  // Parse.
            request = rpc::opMsgRequestFromAnyProtocol(message);
        } catch (const DBException& ex) {
            // If this error needs to fail the connection, propagate it out.
            if (ErrorCodes::isConnectionFatalMessageParseError(ex.code()))
                throw;

            auto operationTime = LogicalClock::get(opCtx)->getClusterTime();
            BSONObjBuilder metadataBob;
            appendReplyMetadataOnError(opCtx, &metadataBob);
            // Otherwise, reply with the parse error. This is useful for cases where parsing fails
            // due to user-supplied input, such as the document too deep error. Since we failed
            // during parsing, we can't log anything about the command.
            LOG(1) << "assertion while parsing command: " << ex.toString();
            _generateErrorResponse(opCtx, replyBuilder.get(), ex, metadataBob.obj(), operationTime);

            return;  // From lambda. Don't try executing if parsing failed.
        }

        try {  // Execute.
            curOpCommandSetup(opCtx, request);

            Command* c = nullptr;
            // In the absence of a Command object, no redaction is possible. Therefore
            // to avoid displaying potentially sensitive information in the logs,
            // we restrict the log message to the name of the unrecognized command.
            // However, the complete command object will still be echoed to the client.
            if (!(c = Command::findCommand(request.getCommandName()))) {
                Command::unknownCommands.increment();
                std::string msg = str::stream() << "no such command: '" << request.getCommandName()
                                                << "'";
                LOG(2) << msg;
                uasserted(ErrorCodes::CommandNotFound,
                          str::stream() << msg << ", bad cmd: '" << redact(request.body) << "'");
            }

            LOG(2) << "run command " << request.getDatabase() << ".$cmd" << ' '
                   << c->getRedactedCopyForLogging(request.body);

            {
                // Try to set this as early as possible, as soon as we have figured out the command.
                stdx::lock_guard<Client> lk(*opCtx->getClient());
                CurOp::get(opCtx)->setLogicalOp_inlock(c->getLogicalOp());
            }

            execCommandDatabase(opCtx, c, request, replyBuilder.get());
        } catch (const DBException& ex) {
            BSONObjBuilder metadataBob;
            appendReplyMetadataOnError(opCtx, &metadataBob);
            auto operationTime = LogicalClock::get(opCtx)->getClusterTime();
            LOG(1) << "assertion while executing command '" << request.getCommandName() << "' "
                   << "on database '" << request.getDatabase() << "': " << ex.toString();

            _generateErrorResponse(opCtx, replyBuilder.get(), ex, metadataBob.obj(), operationTime);
        }
    }();

    if (OpMsg::isFlagSet(message, OpMsg::kMoreToCome)) {
        // Close the connection to get client to go through server selection again.
        uassert(ErrorCodes::NotMaster,
                "Not-master error during fire-and-forget command processing",
                !LastError::get(opCtx->getClient()).hadNotMasterError());

        return {};  // Don't reply.
    }

    auto response = replyBuilder->done();
    CurOp::get(opCtx)->debug().responseLength = response.header().dataLen();

    // TODO exhaust
    return DbResponse{std::move(response)};
}
```

* [&]{}();  这里表示的是匿名lambda函数的定义和运行， 之所以这样写，我猜是为了方便在函数体内使用returen吧。 c++ lambda语法，可以参考， http://zh.cppreference.com/w/cpp/language/lambda
* runCommands第一步，创建一个replyBuilder， 这个很显然，是放了一个response可以用的builder。
* 第二部，就进入了匿名函数内部，首先调用request = rpc::opMsgRequestFromAnyProtocol(message);函数进行request的获取， opMsgRequestFromAnyProtocol如下所示， 因为知道op type是dbMsg， 那么程序会继续执行到OpMsgRequest::parse内部。

```c++
OpMsgRequest opMsgRequestFromAnyProtocol(const Message& unownedMessage) {
    switch (unownedMessage.operation()) {
        case mongo::dbMsg:
            return OpMsgRequest::parse(unownedMessage);
        case mongo::dbQuery:
            return opMsgRequestFromLegacyRequest(unownedMessage);
        case mongo::dbCommand:
            return opMsgRequestFromCommandRequest(unownedMessage);
        default:
            uasserted(ErrorCodes::UnsupportedFormat,
                      str::stream() << "Received a reply message with unexpected opcode: "
                                    << unownedMessage.operation());
    }
}
```

* OpMsgRequest::parse代码如下，可以看出，直接调用了OpMsg::parse进行处理

```c++
    static OpMsgRequest parse(const Message& message) {
        return OpMsgRequest(OpMsg::parse(message));
    }
```

* OpMsg::parse的函数如下

```c++
OpMsg OpMsg::parse(const Message& message) try {
    // It is the caller's responsibility to call the correct parser for a given message type.
    invariant(!message.empty());
    invariant(message.operation() == dbMsg);

    const uint32_t flags = OpMsg::flags(message);
    uassert(ErrorCodes::IllegalOpMsgFlag,
            str::stream() << "Message contains illegal flags value: Ob"
                          << std::bitset<32>(flags).to_string(),
            !containsUnknownRequiredFlags(flags));

    constexpr int kCrc32Size = 4;
    const bool haveChecksum = flags & kChecksumPresent;
    const int checksumSize = haveChecksum ? kCrc32Size : 0;

    // The sections begin after the flags and before the checksum (if present).
    BufReader sectionsBuf(message.singleData().data() + sizeof(flags),
                          message.dataSize() - sizeof(flags) - checksumSize);

    // TODO some validation may make more sense in the IDL parser. I've tagged them with comments.
    bool haveBody = false;
    OpMsg msg;
    while (!sectionsBuf.atEof()) {
        const auto sectionKind = sectionsBuf.read<Section>();
        switch (sectionKind) {
            case Section::kBody: {
                uassert(40430, "Multiple body sections in message", !haveBody);
                haveBody = true;
                msg.body = sectionsBuf.read<Validated<BSONObj>>();
                break;
            }

            case Section::kDocSequence: {
                // We use an O(N^2) algorithm here and an O(N*M) algorithm below. These are fastest
                // for the current small values of N, but would be problematic if it is large.
                // If we need more document sequences, raise the limit and use a better algorithm.
                uassert(ErrorCodes::TooManyDocumentSequences,
                        "Too many document sequences in OP_MSG",
                        msg.sequences.size() < 2);  // Limit is <=2 since we are about to add one.

                // The first 4 bytes are the total size, including themselves.
                const auto remainingSize =
                    sectionsBuf.read<LittleEndian<int32_t>>() - sizeof(int32_t);
                BufReader seqBuf(sectionsBuf.skip(remainingSize), remainingSize);
                const auto name = seqBuf.readCStr();
                uassert(40431,
                        str::stream() << "Duplicate document sequence: " << name,
                        !msg.getSequence(name));  // TODO IDL

                msg.sequences.push_back({name.toString()});
                while (!seqBuf.atEof()) {
                    msg.sequences.back().objs.push_back(seqBuf.read<Validated<BSONObj>>());
                }
                break;
            }

            default:
                // Using uint32_t so we append as a decimal number rather than as a char.
                uasserted(40432, str::stream() << "Unknown section kind " << uint32_t(sectionKind));
        }
    }

    uassert(40587, "OP_MSG messages must have a body", haveBody);

    // Detect duplicates between doc sequences and body. TODO IDL
    // Technically this is O(N*M) but N is at most 2.
    for (const auto& docSeq : msg.sequences) {
        const char* name = docSeq.name.c_str();  // Pointer is redirected by next call.
        auto inBody =
            !dotted_path_support::extractElementAtPathOrArrayAlongPath(msg.body, name).eoo();
        uassert(40433,
                str::stream() << "Duplicate field between body and document sequence "
                              << docSeq.name,
                !inBody);
    }

    return msg;
} catch (const DBException& ex) {
    LOG(1) << "invalid message: " << ex.code() << " " << redact(ex) << " -- "
           << redact(hexdump(message.singleData().view2ptr(), message.size()));
    throw;
}
```

