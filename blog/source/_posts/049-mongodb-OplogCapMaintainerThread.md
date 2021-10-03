---
title: 049-mongodb-OplogCapMaintainerThread
date: 2021-09-21 15:06:00
tags:
---



### OplogCapMaintainerThread

<!--more-->

* OplogCapMaintainerThread
  * 主要是为了 清理掉超过 oplog size 大小的 oplog 数据准备的， 如果上次删除失败，那么会等待 1s 后继续删除，
  * 如果上次删除成功，则继续执行删除操作， _deleteExcessDocuments
  * _deleteExcessDocuments 应该会await 在 yieldAndAwaitOplogDeletionRequest 这里，(未经过测试)
  * 这里会有一个新的概念， oplogStones
    * oplogStones 的具体定义，请参考 代码仓库的 readme， 这里仅仅列出一些设计点.
    * oplogStones 存不存到 oplog里?
      * 答案:  oplogStones 是不存在 oplog里的.
    * oplogStones 存不存在数据库里?
      * 答案:  oplogStones 不存在数据库里.
    * 系统启动的时候， 针对 几十个G的oplog， 如何恢复  oplogStones,
      * 答案: 靠计算， 也就是估算 oplogStones. 每次重启，都是估算构建的一个过程.
    *  oplogStones 有什么用
      * 答案: 用于快速定位需要删除到的 recordId, oplogStones 记录了自己到上一个 stone 的oplog的大小，所以只需要简单的遍历 oplogStones， 就可以快速计算出应该把oplog删除到
  * 删除逻辑，调用的是 rs->reclaimOplog(opCtx.get());  调用 session->truncate 命令进行删除