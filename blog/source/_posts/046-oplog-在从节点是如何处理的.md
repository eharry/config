---
title: 046-oplog-在从节点是如何处理的
date: 2021-09-20 20:25:31
tags: Mongodb, oplog
---



# oplog 是如何在从节点处理的

* oplog 在从节点是如何被获取的
* oplog 在从节点是如何被写入的
* oplog 在从节点是如何被回放的

<!--more-->



## oplog 在从节点是如何被获取的

* 从节点 启动线程读取 主节点 oplog

  * 背景知识

    * mongod_main 函數， 会调用 setUpReplication， setUpReplication 会调用 ReplicationCoordinatorImpl， 
    * ReplicationCoordinatorExternalStateImpl 的 startSteadyStateReplication 会调用 _bgSync->startup, 
    * 然后会调用到 BackgroundSync::_run 这个函数里， mongodb 代码里的 src/mongo/repl/bgsync.cpp 主要就是 fetcher 这个逻辑
    * 最后 BackgroundSync::_produce 这个函数，会调用本次讨论的主角， 创建一个 OplogFetcher 并 调用 oplogFetcher->startup(), oplogFetcher->join()

  * OplogFetcher 介绍:

    * The oplog fetcher, once started, reads operations from a remote oplog using a tailable, awaitData, exhaust cursor. [oplog fether, 是一个 exhaust cursor, 就是持续的从远端读取 oplog 的 cursor， 是不会结束的]
    * OplogFetcher 读到的数据，都会调用回调函数， 也就是 BackgroundSync::_enqueueDocuments, 这个函数则直接调用了 _oplogApplier->enqueue 加入到回放队列里, 
    * 这里就将  远程 oplog 拉去和 oplog 回放结合了起来。

## oplog 在从节点是如何被写入的 & 如何被回放的

* OplogApplier 的 enqueue 函数，是将 oplog 信息放到了 成员变量 _oplogBuffer 里的，

* OplogApplier 的另一个成员函数 _oplogBatcher， 也使用了 _oplogBuffer 这个成员变量， 所以 _oplogBatcher->getNextBatch 也能拿到相应的 oplog 信息， 具体的回放函数主题在:  OplogApplierImpl::_run, 这个是主函数的代码，这个代码就比 4.0.3 放到一个 所谓的 sync_tail 里，要规整多了,

* logApplierImpl::_run 介绍:

  * step1: 从 buffer 中拿到用于处理的oplog

    * ```c++
      OplogBatch ops = _oplogBatcher->getNextBatch(Seconds(1));
      ```

  * step2: 处理这些 oplog， 

    * ```c++
      auto swLastOpTimeAppliedInBatch = _applyOplogBatch(&opCtx, ops.releaseBatch());
      ```

  * step3: 更新后续的一些元数据，时间戳之类的

* _applyOplogBatch 介绍:

  * step 1: 启动线程 将这些 oplog 写入到 本节点

    * ```c++
      scheduleWritesToOplog(opCtx, _storageInterface, _writerPool, ops);
      ```

  * step 2: 划分 oplog的回放方式，尽可能的并行划分

    * ```c++
      fillWriterVectors(opCtx, &ops, &writerVectors, &derivedOps);
      ```

  * step 3: 并行回放 oplog

    * ```c++
      for (size_t i = 0; i < writerVectors.size(); i++) {
          if (writerVectors[i].empty())
              continue;
      
          _writerPool->schedule([this,
                                 &writer = writerVectors.at(i),
                                 &status = statusVector.at(i),
                                 &multikeyVector = multikeyVector.at(i),
                                 isDataConsistent = isDataConsistent](auto scheduleStatus) {
              invariant(scheduleStatus);
      
              auto opCtx = cc().makeOperationContext();
      
              // This code path is only executed on secondaries and initial syncing nodes,
              // so it is safe to exclude any writes from Flow Control.
              opCtx->setShouldParticipateInFlowControl(false);
              opCtx->setEnforceConstraints(false);
      
              status = opCtx->runWithoutInterruptionExceptAtGlobalShutdown([&] {
                  return applyOplogBatchPerWorker(
                      opCtx.get(), &writer, &multikeyVector, isDataConsistent);
              });
          });
      }
      ```

