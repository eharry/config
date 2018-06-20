### 如何使用脚本查看mongod的core dump log

* mongod log如下

```txt
2018-06-20T08:38:01.305+0800 E STORAGE  [conn11768] WiredTiger (0) [1529455081:305701][19362:0x7fd21583f700], WT_SESSION.reset: scratch buffer allocated and never discarded
2018-06-20T08:38:01.804+0800 F -        [conn11768] Got signal: 6 (Aborted).

 0x15c3641 0x15c2499 0x15c2dc1 0x7fd235293390 0x7fd234eed428 0x7fd234eef02a 0x16adb68 0x16b5417 0x1e2ecf5 0x1d194e6 0x1d10fdf 0x1d1136b 0x12b43a1 0x12b1297 0x12b1321 0xe3990c 0xe39961 0x9d06ee 0x155a66b 0x7fd2352896ba 0x7fd234fbf41d
----- BEGIN BACKTRACE -----
{"backtrace":[{"b":"400000","o":"11C3641","s":"_ZN5mongo15printStackTraceERSo"},{"b":"400000","o":"11C2499"},{"b":"400000","o":"11C2DC1"},{"b":"7FD235282000","o":"11390"},{"b":"7FD234EB8000","o":"35428","s":"gsignal"},{"b":"7FD234EB8000","o":"3702A","s":"abort"},{"b":"400000","o":"12ADB68"},{"b":"400000","o":"12B5417"},{"b":"400000","o":"1A2ECF5","s":"_ZdaPv"},{"b":"400000","o":"19194E6","s":"__wt_scr_discard"},{"b":"400000","o":"1910FDF","s":"__wt_session_release_resources"},{"b":"400000","o":"191136B"},{"b":"400000","o":"EB43A1","s":"_ZN5mongo22WiredTigerSessionCache14releaseSessionEPNS_17WiredTigerSessionE"},{"b":"400000","o":"EB1297","s":"_ZN5mongo22WiredTigerRecoveryUnitD1Ev"},{"b":"400000","o":"EB1321","s":"_ZN5mongo22WiredTigerRecoveryUnitD0Ev"},{"b":"400000","o":"A3990C","s":"_ZN5mongo20OperationContextImplD1Ev"},{"b":"400000","o":"A39961","s":"_ZN5mongo20OperationContextImplD0Ev"},{"b":"400000","o":"5D06EE"},{"b":"400000","o":"115A66B","s":"_ZN5mongo17PortMessageServer17handleIncomingMsgEPv"},{"b":"7FD235282000","o":"76BA"},{"b":"7FD234EB8000","o":"10741D","s":"clone"}],"processInfo":{ "mongodbVersion" : "3.2.18", "gitVersion" : "4c1bae566c0c00f996a2feb16febf84936ecaf6f", "compiledModules" : [], "uname" : { "sysname" : "Linux", "release" : "4.4.0-104-generic", "version" : "#127-Ubuntu SMP Mon Dec 11 12:16:42 UTC 2017", "machine" : "x86_64" }, "somap" : [ { "elfType" : 2, "b" : "400000", "buildId" : "52BC2A2C93142FC2C45404E8D11874CEFE10DE89" }, { "b" : "7FFD267FA000", "elfType" : 3, "buildId" : "BF4B5E36B7E2464DCF29A888C247A27A3FF2BC5C" }, { "b" : "7FD23620E000", "path" : "/lib/x86_64-linux-gnu/libssl.so.1.0.0", "elfType" : 3, "buildId" : "DCF10134B91ED2139E3E8C72564668F5CDBA8522" }, { "b" : "7FD235DCA000", "path" : "/lib/x86_64-linux-gnu/libcrypto.so.1.0.0", "elfType" : 3, "buildId" : "1649272BE0CA9FA22F082DC86372B6C9959779B0" }, { "b" : "7FD235BC2000", "path" : "/lib/x86_64-linux-gnu/librt.so.1", "elfType" : 3, "buildId" : "89C34D7A182387D76D5CDA1F7718F5D58824DFB3" }, { "b" : "7FD2359BE000", "path" : "/lib/x86_64-linux-gnu/libdl.so.2", "elfType" : 3, "buildId" : "8CC8D0D119B142D839800BFF71FB71E73AEA7BD4" }, { "b" : "7FD2356B5000", "path" : "/lib/x86_64-linux-gnu/libm.so.6", "elfType" : 3, "buildId" : "DFB85DE42DAFFD09640C8FE377D572DE3E168920" }, { "b" : "7FD23549F000", "path" : "/lib/x86_64-linux-gnu/libgcc_s.so.1", "elfType" : 3, "buildId" : "68220AE2C65D65C1B6AAA12FA6765A6EC2F5F434" }, { "b" : "7FD235282000", "path" : "/lib/x86_64-linux-gnu/libpthread.so.0", "elfType" : 3, "buildId" : "CE17E023542265FC11D9BC8F534BB4F070493D30" }, { "b" : "7FD234EB8000", "path" : "/lib/x86_64-linux-gnu/libc.so.6", "elfType" : 3, "buildId" : "B5381A457906D279073822A5CEB24C4BFEF94DDB" }, { "b" : "7FD236477000", "path" : "/lib64/ld-linux-x86-64.so.2", "elfType" : 3, "buildId" : "5D7B6259552275A3C17BD4C3FD05F5A6BF40CAA5" } ] }}
 mongod(_ZN5mongo15printStackTraceERSo+0x41) [0x15c3641]
 mongod(+0x11C2499) [0x15c2499]
 mongod(+0x11C2DC1) [0x15c2dc1]
 libpthread.so.0(+0x11390) [0x7fd235293390]
 libc.so.6(gsignal+0x38) [0x7fd234eed428]
 libc.so.6(abort+0x16A) [0x7fd234eef02a]
 mongod(+0x12ADB68) [0x16adb68]
 mongod(+0x12B5417) [0x16b5417]
 mongod(_ZdaPv+0x255) [0x1e2ecf5]
 mongod(__wt_scr_discard+0x56) [0x1d194e6]
 mongod(__wt_session_release_resources+0x6F) [0x1d10fdf]
 mongod(+0x191136B) [0x1d1136b]
 mongod(_ZN5mongo22WiredTigerSessionCache14releaseSessionEPNS_17WiredTigerSessionE+0x81) [0x12b43a1]
 mongod(_ZN5mongo22WiredTigerRecoveryUnitD1Ev+0x37) [0x12b1297]
 mongod(_ZN5mongo22WiredTigerRecoveryUnitD0Ev+0x11) [0x12b1321]
 mongod(_ZN5mongo20OperationContextImplD1Ev+0x5C) [0xe3990c]
 mongod(_ZN5mongo20OperationContextImplD0Ev+0x11) [0xe39961]
 mongod(+0x5D06EE) [0x9d06ee]
 mongod(_ZN5mongo17PortMessageServer17handleIncomingMsgEPv+0x31B) [0x155a66b]
 libpthread.so.0(+0x76BA) [0x7fd2352896ba]
 libc.so.6(clone+0x6D) [0x7fd234fbf41d]
-----  END BACKTRACE  -----

```
* run.sh 的使用说明如下所示

```bash
# ./run.sh
run.sh loadMongodbDisk
run.sh deployMongoBinary path
run.sh configReplica
run.sh remoteCmd [k|s|q|initRepl|createUser|clean|showdbs|dropDatabase database|remount options|cleanAuditLog|shutdownOpLog]
run.sh deployYCSB
run.sh runYCSB workload threadNum [load|run] logPath
run.sh updateAdminWhiteList
run.sh mtu eth number
run.sh calcOffset functionName offset1 addr debugBinaryPath
run.sh showStack offset debugBinaryPath addr[ ...]
```



* 使用脚本 run.sh, 选取log中其中一行带有详细函数信息的log,用于计算偏移量
* 选取log如下所示

```c++
 mongod(_ZN5mongo22WiredTigerSessionCache14releaseSessionEPNS_17WiredTigerSessionE+0x81) [0x12b43a1]
```

* 计算偏移量方法如下所示, 这个例子计算出 偏移量为0, 实际环境可能不是0

```bash
# ./run.sh calcOffset _ZN5mongo22WiredTigerSessionCache14releaseSessionEPNS_17WiredTigerSessionE 0x81 0x12b43a1 /data/cuixin/mongodb3.2.18.gcc.5.4/code/dds/code/mongod.debug
resultStr: 00000000012b4320 T mongo::WiredTigerSessionCache::releaseSession(mongo::WiredTigerSession*)
offsetReal is 0

```

* 根据log中,批量log信息,得到打印堆栈

```txt
0x15c3641 0x15c2499 0x15c2dc1 0x7fd235293390 0x7fd234eed428 0x7fd234eef02a 0x16adb68 0x16b5417 0x1e2ecf5 0x1d194e6 0x1d10fdf 0x1d1136b 0x12b43a1 0x12b1297 0x12b1321 0xe3990c 0xe39961 0x9d06ee 0x155a66b 0x7fd2352896ba 0x7fd234fbf41d
```

* 调用run.sh, 得到对战信息

```bash
# ./run.sh showStack 0 /data/cuixin/mongodb3.2.18.gcc.5.4/code/dds/code/mongod.debug  0x15c3641 0x15c2499 0x15c2dc1 0x7fd235293390 0x7fd234eed428 0x7fd234eef02a 0x16adb68 0x16b5417 0x1e2ecf5 0x1d194e6 0x1d10fdf 0x1d1136b 0x12b43a1 0x12b1297 0x12b1321 0xe3990c 0xe39961 0x9d06ee 0x155a66b 0x7fd2352896ba 0x7fd234fbf41d                                                                                 mongo::printStackTrace(std::ostream&)
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/util/stacktrace_posix.cpp:172
mongo::(anonymous namespace)::printSignalAndBacktrace(int)
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/util/signal_handlers_synchronous.cpp:182
mongo::(anonymous namespace)::abruptQuit(int)
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/util/signal_handlers_synchronous.cpp:238
??
??:0
??
??:0
??
??:0
tcmalloc::Log(tcmalloc::LogMode, char const*, int, tcmalloc::LogItem, tcmalloc::LogItem, tcmalloc::LogItem, tcmalloc::LogItem)
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/internal_logging.cc:120
(anonymous namespace)::InvalidFree(void*)
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:279
free_null_or_invalid
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:1173
do_free_helper
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:1217
do_free_with_callback
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:1260
do_free
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:1266
tc_deletearray
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/gperftools-2.2/src/tcmalloc.cc:1697
memset
/usr/include/x86_64-linux-gnu/bits/string3.h:90
__wt_buf_free
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/wiredtiger/src/include/buf.i:107
__wt_scr_discard
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/wiredtiger/src/support/scratch.c:331
__wt_buf_free
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/wiredtiger/src/include/buf.i:105
__wt_session_release_resources
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/wiredtiger/src/session/session_api.c:107
__session_reset
/data/cuixin/mongodb3.2.18/code/dds/code/src/third_party/wiredtiger/src/session/session_api.c:824
mongo::WiredTigerSessionCache::releaseSession(mongo::WiredTigerSession*)
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/storage/wiredtiger/wiredtiger_session_cache.cpp:323
mongo::WiredTigerRecoveryUnit::~WiredTigerRecoveryUnit()
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/storage/wiredtiger/wiredtiger_recovery_unit.cpp:67
mongo::WiredTigerRecoveryUnit::~WiredTigerRecoveryUnit()
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/storage/wiredtiger/wiredtiger_recovery_unit.cpp:69
mongo::OperationContext::~OperationContext()
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/operation_context.h:73
mongo::OperationContextImpl::~OperationContextImpl()
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/operation_context_impl.cpp:90
mongo::OperationContextImpl::~OperationContextImpl()
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/operation_context_impl.cpp:95
mongo::Message::empty() const
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/util/net/message.h:440
process
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/db/db.cpp:187
mongo::PortMessageServer::handleIncomingMsg(void*)
/data/cuixin/mongodb3.2.18/code/dds/code/src/mongo/util/net/message_server_port.cpp:252
??
??:0
??
??:0

```

