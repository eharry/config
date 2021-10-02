---
title: 045-mongodb-pipeline
date: 2021-09-20 10:00:03
tags: Mongodb, aggregation, pipeline
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

Starting in MongoDB 4.2, you can use the aggregation pipeline for updates in:

MongoDB 4.2 开始， 可以使用 aggregation pipeline 进行 update 操作:

| Command                                                      | `mongosh` Methods                                            |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [`findAndModify`](https://docs.mongodb.com/manual/reference/command/findAndModify/#mongodb-dbcommand-dbcmd.findAndModify) | [db.collection.findOneAndUpdate()](https://docs.mongodb.com/manual/reference/method/db.collection.findOneAndUpdate/#std-label-findOneAndUpdate-agg-pipeline)[db.collection.findAndModify()](https://docs.mongodb.com/manual/reference/method/db.collection.findAndModify/#std-label-findAndModify-agg-pipeline) |
| [`update`](https://docs.mongodb.com/manual/reference/command/update/#mongodb-dbcommand-dbcmd.update) | [db.collection.updateOne()](https://docs.mongodb.com/manual/reference/method/db.collection.updateOne/#std-label-updateOne-example-agg)[db.collection.updateMany()](https://docs.mongodb.com/manual/reference/method/db.collection.updateMany/#std-label-updateMany-example-agg)[db.collection.update()](https://docs.mongodb.com/manual/reference/method/db.collection.update/#std-label-update-example-agg)[Bulk.find.update()](https://docs.mongodb.com/manual/reference/method/Bulk.find.update/#std-label-example-bulk-find-update-agg)[Bulk.find.updateOne()](https://docs.mongodb.com/manual/reference/method/Bulk.find.updateOne/#std-label-example-bulk-find-update-one-agg)[Bulk.find.upsert()](https://docs.mongodb.com/manual/reference/method/Bulk.find.upsert/#std-label-bulk-find-upsert-update-agg-example) |

[Updates with Aggregation Pipeline](https://docs.mongodb.com/manual/tutorial/update-documents-with-aggregation-pipeline/)



## Pipeline Expressions

有些 pipeline stages 可以使用 pipeline expression 作为算子。Pipeline expressions 制定了一个转换形式来使用输入的参数. Expressions 可以包含一个文档结构，也可以包含其他的 expression.

pipeline expressions 只能对当前 文档进行操作， 不能指定其他文档进行操作。 

通常情况下，expressions 是无状态的，并且只能被当前的 聚合线程所使用， 但是有一个例外: accumulator

accumulators 用在 $group stage里，用于维护它的状态(例如， 全量，最大值，最小值和。。。)

从4.4 开始， mongodb 提供了 $accumulator 和 $function 这两个聚合操作。 这些操作为用户提供了可以自定义聚合方式的功能。

更详细的信息，请参看  [Expressions](https://docs.mongodb.com/manual/meta/aggregation-quick-reference/#std-label-aggregation-expressions).



## Aggregation Pipeline Behavior

aggregate 命令使用在一个表上， 用来逻辑的处理整个表的到 aggregation pipeline. 为了优化这个过古城，我们使用下面几种方法来避免全表扫描



### Pipeline Operators and Indexes

mongodb [query planner](https://docs.mongodb.com/manual/core/query-plans/#std-label-query-plans-query-optimization)  会分析整个 aggregation pipeline 来决定哪些 indexes 可以被用来提高 整个 pipeline的运行效率。 下面的这些 stages就可以从 indexes中获益:

NOTE

这里并没有全部刘彻可以用来使用 index的所有stages

- `$match`

  如果 $match stage 在 pipeline 的一开始，那么可以用来 index 来过滤掉一些文档

- `$sort`

  $sort stage 可以使用索引，只要这个 sort 不在 $project, $unwind, $group stage 前面

- `$group`

  $group stage 有时候可以使用 索引 来查找每个分组第一个出现的文档， 如果下面的条件的都满足的话:

  $group stage 在 $sort stage 前面， 存在一个index 在 group的字段上并且符合这个sort 的顺序， 并且 $group stage 使用了 $first。 具体信息可以参考  [Optimization to Return the First Document of Each Group](https://docs.mongodb.com/manual/reference/operator/aggregation/group/#std-label-group-pipeline-optimization) 

- `$geoNear`

  $geoNear pipeline operator 可以 使用 geospatial index 索引。 当使用 [`$geoNear`](https://docs.mongodb.com/manual/reference/operator/aggregation/geoNear/#mongodb-pipeline-pipe.-geoNear) 时， $geoNear 必须在 aggregation pipeline的第一个 stage.

*Changed in version 3.2*: Starting in MongoDB 3.2, indexes can [cover](https://docs.mongodb.com/manual/core/query-optimization/#std-label-read-operations-covered-query) an aggregation pipeline. In MongoDB 2.6 and 3.0, indexes could not cover an aggregation pipeline since even when the pipeline uses an index, aggregation still requires access to the actual documents.

### Early Filtering

If your aggregation operation requires only a subset of the data in a collection, use the [`$match`](https://docs.mongodb.com/manual/reference/operator/aggregation/match/#mongodb-pipeline-pipe.-match), [`$limit`](https://docs.mongodb.com/manual/reference/operator/aggregation/limit/#mongodb-pipeline-pipe.-limit), and [`$skip`](https://docs.mongodb.com/manual/reference/operator/aggregation/skip/#mongodb-pipeline-pipe.-skip) stages to restrict the documents that enter at the beginning of the pipeline. When placed at the beginning of a pipeline, [`$match`](https://docs.mongodb.com/manual/reference/operator/aggregation/match/#mongodb-pipeline-pipe.-match) operations use suitable indexes to scan only the matching documents in a collection.

Placing a [`$match`](https://docs.mongodb.com/manual/reference/operator/aggregation/match/#mongodb-pipeline-pipe.-match) pipeline stage followed by a [`$sort`](https://docs.mongodb.com/manual/reference/operator/aggregation/sort/#mongodb-pipeline-pipe.-sort) stage at the start of the pipeline is logically equivalent to a single query with a sort and can use an index. When possible, place [`$match`](https://docs.mongodb.com/manual/reference/operator/aggregation/match/#mongodb-pipeline-pipe.-match) operators at the beginning of the pipeline.

## Considerations

### Aggregation Pipeline Limitations

An aggregation pipeline has some limitations on the value types and the result size. See [Aggregation Pipeline Limits](https://docs.mongodb.com/manual/core/aggregation-pipeline-limits/).

### Aggregation Pipeline Optimization

An aggregation pipeline has an internal optimization phase that provides improved performance for certain sequences of operators. See [Aggregation Pipeline Optimization](https://docs.mongodb.com/manual/core/aggregation-pipeline-optimization/).

### Aggregation on Sharded Collections

An aggregation pipeline supports operations on sharded collections. See [Aggregation Pipeline and Sharded Collections](https://docs.mongodb.com/manual/core/aggregation-pipeline-sharded-collections/#std-label-aggregation-pipeline-sharded-collection).

### Aggregation Pipeline as an Alternative to Map-Reduce

As of MongoDB 5.0 the [map-reduce](https://docs.mongodb.com/manual/core/map-reduce/) operation is deprecated.

An [aggregation pipeline](https://docs.mongodb.com/manual/core/aggregation-pipeline/) provides better performance and usability than a [map-reduce](https://docs.mongodb.com/manual/core/map-reduce/) operation.

Map-reduce operations can be rewritten using [aggregation pipeline operators](https://docs.mongodb.com/manual/meta/aggregation-quick-reference/), such as [`$group`](https://docs.mongodb.com/manual/reference/operator/aggregation/group/#mongodb-pipeline-pipe.-group), [`$merge`](https://docs.mongodb.com/manual/reference/operator/aggregation/merge/#mongodb-pipeline-pipe.-merge), and others.

For map-reduce operations that require custom functionality, MongoDB provides the [`$accumulator`](https://docs.mongodb.com/manual/reference/operator/aggregation/accumulator/#mongodb-group-grp.-accumulator) and [`$function`](https://docs.mongodb.com/manual/reference/operator/aggregation/function/#mongodb-expression-exp.-function) aggregation operators starting in version 4.4. Use these operators to define custom aggregation expressions in JavaScript.

For examples of aggregation pipeline alternatives to map-reduce operations, see [Map-Reduce to Aggregation Pipeline](https://docs.mongodb.com/manual/reference/map-reduce-to-aggregation-pipeline/) and [Map-Reduce Examples](https://docs.mongodb.com/manual/tutorial/map-reduce-examples/).
