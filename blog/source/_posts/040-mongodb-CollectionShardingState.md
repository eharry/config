---
title: 040-mongodb-CollectionShardingState
date: 2021-08-01 14:26:30
tags:
---

代码初步走读了 CollectionShardingState 

<!--more-->


* CollectionShardingState
  * 每一个 collection 对应一个 CollectionShardingState 的对象，  
    * 分片表对应的对象是: CollectionShardingRuntime
    * 非分片表对应的对象是: CollectionShardingStateStandalone
      * CollectionShardingStateStandalone 基本上就是空的实现.
  * /成员函数:
    * 公有函数
      * getCollectionDescription, 返回 collection 的元数据， 大部分用于判断表是否是 shard的.
      * getOwnershipFilter,  内部实现是一样的， 也返回的是元数据， ScopedCollectionFilter 是 ScopedCollectionDescription 的子类，里面多实现了一个函数 keyBelongsToMe ， 看样子是为了 进行filter 用的。 也是为了 shard 自身用于判断 key是否属于自己所使用的。
      * checkShardVersionOrThrow 检查 operation context里 所带的shard 版本是否跟 collection 内部的shard collection 一致， 如果不一致，会抛出异常 StaleConfigException 出来。
      * numberOfRangesScheduledForDeletion 返回当前有多少个 reange deletion， 看样子跟 migration 相关，在 migration 的最后阶段删除数据使用的， 如果是多个的话？那么意味着， mongodb 支持多个chunk 并发的 migration 迁移了？
* 有几个子类？
  * 两个子类，  CollectionShardingRuntime， CollectionShardingStateStandalone
  * 两个创建的工厂:
    * CollectionShardingStateFactoryShard, CollectionShardingStateFactoryStandalone
    * 这两个工厂被设置到到了 CollectionShardingStateFactory 里面, 被作为全家变量 CollectionShardingStateMap 的 内部 factory 进行使用， 
* 如何创建的， 
  * 并没有固定的创建流程，是采用 getOrCreate的方式，在使用的时候，如果发现没有，就创建的。
* 如何删除的
  * 删除逻辑没有找到，应该是没有删除逻辑。
* 工厂创建的具体逻辑
  * 没有额外的创建逻辑，只是在构造的时候， 传入了 servercontext， nss，和 rangedeleteexecutor. 

