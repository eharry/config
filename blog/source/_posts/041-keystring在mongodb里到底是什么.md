---
layout: port
title: 041-keystring在mongodb里到底是什么
date: 2021-08-02 22:24:35
tags:
---

* 什么是 key string?

<!--more-->

  * key string 就是 mongodb doc的索引的编码方式。

  * 我们知道 mongodb的 recordid， 就是 底层 key value engine的 key， 这个 recordid 需要具备以下几个特点 

    * 当存储的是 mongodb doc 完整信息的时候，  recordid 是 一个 uint64_t 的整数，只需要递增就好了
    * 当存储的是 索引信息的时候， 我们就需要对 索引信息进行编码，生成一个  recordId, 之后对这个 recordid的排序，就是对这个索引信息的排序。

  * 既然key string是用来进行key编码的，那么就有一个问题， mongodb 时候如何做到 key 编码后的值跟，编码前的索引，排序是一致的呢。

  * 这里做个实验， 看一下，具体的key，编码到底是什么？

    ```bash
    "msg":"{keyString}","attr":{"keyString":"2B04040010"}} 
    ```

    * 2B 表示索引类型第一个字段是 整型数字,  并且只有一个字节大小 0,
    * write 流程:
      * _performInsert -> insertDocument -> _indexCatalog->indexRecords -> {index->accessMethod()->getKeys, _indexKeys}
      * keystring 生成，就在 getKeys 上, 最后落到了 treeKeyGenerator::getKeys 这个执行函数里
      

