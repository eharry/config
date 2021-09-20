---
title: 045-mongodb-pipeline
date: 2021-09-20 10:00:03
tags:
---



* Mongodb Pipeline 介绍
  * https://docs.mongodb.com/manual/core/aggregation-pipeline/ 此文档翻译



<!--more-->

# Aggregation Pipeline

aggregation pipeline 是一个数据库处理的框架，由一系列的数据处理流水线组成。 文档数据通过一系列的流水线处理，将文档转化为最后的聚合结果: 

```bash
db.orders.aggregate([
   { $match: { status: "A" } },
   { $group: { _id: "$cust_id", total: { $sum: "$amount" } } }
])
```

第一个stage: $match stage 用于过滤文档 orders 中的数据， 并将符合条件的数据传递到下一个 stage 上.

第二个stage: $group stage 按照 $cust_id 进行分组，然后统计每一个 amount 的值，并输出. 

## Pipeline

The MongoDB aggregation pipeline consists of [stages](https://docs.mongodb.com/manual/reference/operator/aggregation-pipeline/#std-label-aggregation-pipeline-operator-reference). Each stage transforms the documents as they pass through the pipeline. Pipeline stages do not need to produce one output document for every input document. For example, some stages may generate new documents or filter out documents.

Mongodb 聚合流水想由一系列的stages 组成. 每个 stage 都会负责讲传入的文档进行转换。 但是 stage 并不一定要做到一个输入就要有一个输出。 有些 stage 就会产生新的文档，而有些 stage 则会过滤掉一些文档.  

Pipeline stages 可以出现多次，除了 $out, $merge, $geoNear 这些stage.  所有的 stage 信息，可以看这个文档: [Aggregation Pipeline Stages](https://docs.mongodb.com/manual/reference/operator/aggregation-pipeline/#std-label-aggregation-pipeline-operator-reference).

MongoDB 提供 db.collection.aggregate() shell 命令和 aggregate 命令用来运行 aggregation pipeline.

一些 aggregation pipeline 的例子，可以考虑这两个文档, [Aggregation with User Preference Data](https://docs.mongodb.com/manual/tutorial/aggregation-with-user-preference-data/) and [Aggregation with the Zip Code Data Set](https://docs.mongodb.com/manual/tutorial/aggregation-zip-code-data-set/).
