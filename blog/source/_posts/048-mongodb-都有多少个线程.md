---
title: 048-mongodb-都有多少个线程
date: 2021-09-20 22:21:15
tags:
---



### mongodb-都有多少个线程

<!--more-->

* 线程列表, 排除了代码中 客户端调用线程的情况，只考虑服务端的线程情况

  * AlarmRunnerBackgroundThread

  * BackgroundThreadClockSource

  * BackgroundJob

    * PeriodicTaskRunner
      * DBConnectionPool 
        * 竟然是 PeriodicTask 的一个子类， 全局只有一个 DBConnectionPool 对象，为 globalConnPool
        * DBConnectionPool 的 taskDoWork 方法主要负责，清理 连接池中，空闲超期的连接，并将他们清理掉， 超时参数由 globalConnPoolIdleTimeoutMinutes 控制，默认 为最大值
    * ClientCursorMonitor
      * 线程名字为 clientcursormon， 每隔 clientCursorMonitorFrequencySecs 秒，监控系统中游标超时的情况， 默认间隔时间为 4 s.
      * cursorTimeoutMillis, 游标超时时间默认为 600s， 通过 cursorTimeoutMillis 设置.
    * Checkpointer
      * 这个线程周期性的 调用存储引擎的 checkpoint 接口，做 checkpoint 工作， 工作主题大体分为三部分， 
        * storage.syncPeriodSecs 设置可以决定 每次 checkpoint的间隔时间， 但实际上 checkpoint 的触发频率是有时间和 信号量两者共同触发的。 
          * 在信号量触发逻辑里:
            * 由函数 Checkpointer::triggerFirstStableCheckpoint 进行触发， 但注意，这里只能触发第一次的 checkpoint，后续的 checkpoint 都是定期执行的。
        * 调用 _kvEngine->checkpoint(); 执行真正的 checkpoint，
        * 最后还记录一个运行时间，如果超过30s，需要记录日志
    * OplogCapMaintainerThread
      * 这个比较重要，单独文章介绍
    * WiredTigerKVEngine::WiredTigerSessionSweeper
    * JournalFlusher
    * DbCheckJob
    * FSyncLockThread
    * TTLMonitor
    * ClusterCursorCleanupJob

  * PeriodicRunnerImpl

    * CertificateExpirationMonitor::start
  * OCSPFetcher::startPeriodicJob
    * UserCacheInvalidator::start
  * ServiceLiaisonMongod::scheduleJob
    * ServiceLiaisonMongos::scheduleJob
  * PeriodicThreadToAbortExpiredTransactions::_init
    * launchBalancerConfigRefresher
  * PeriodicShardedIndexConsistencyChecker::_launchShardedIndexConsistencyChecker
    * FlowControl::FlowControl
  * StorageEngineImpl::TimestampMonitor::_startup

  * AuthorizationManagerImpl::updatePinned

  * UsersList

  * KeysCollectionManager

  * FreeMonController

  * ApplyBatchFinalizerForJournal

  * BackgroundSync

  * NoopWriter::PeriodicNoopRunner

  * TopologyVersionObserver

  * ReplicationCoordinatorImpl::AutoGetRstlForStepUpStepDown::_startKillOpThread

  * ReplicationCoordinatorExternalStateImpl

  * OplogBatcher

  * SessionKiller

  * TrafficRecorder::Recording

  * PosixTimer

  * SessionCatalogMigrationDestination

  * MigrationDestinationManager

  * ReplSetDistLockManager::startUp

  * BalancerCommandsSchedulerImpl

  * WiredTigerOplogManager

  * ShardingUptimeReporter::startPeriodicThread

  * TransportLayerASIO

  * launchServiceWorkerThread

  * TransportLayerASIO::start

* 具体每个线程的含义，参考后续文档
