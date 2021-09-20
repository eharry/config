---
title: 043-Mongodb-timeseries-readme
date: 2021-08-10 07:04:07
tags: mongodb timeseries
---

这是一篇文档翻译，里面加入我个人理解的时候，会额外标注出来。
英文地址在: mongodb master分支的 src/mongo/db/timeseries/README.md
<!--more-->

# Time-Series Collections

MongoDB supports a new collection type for storing time-series data with the [timeseries](../commands/create.idl)
collection option. A time-series collection presents a simple interface for inserting and querying
measurements while organizing the actual data in buckets.

MongoDB 支持一种新的表类型用于专门存储时序信息,通过 timeseries 选项来表明。 时序库提供一个简单的接口用于插入和查询 measurements 当这些时序数据真正的被组织在 buckets 里面的时候。
译者注:
  timeseries idl 定义如下:
  ```bash
  server_parameters:
    "timeseriesBucketMaxCount":
        description: "Maximum number of measurements to store in a single bucket"
         ^^^^^ 这个配置设置了一个 bucket 里最多能存多少个 时序记录。 这个值只能启动时修改，不能运行时修改。 为什么不能运行时修改，还不知道。 我个人理解是可以运行时修改的。
        set_at: [ startup ]
        cpp_vartype: "std::int32_t"
        cpp_varname: "gTimeseriesBucketMaxCount"
        default: 1000
        validator: { gte: 1 }
    "timeseriesBucketMaxSize":
        description: "Maximum size in bytes of measurements to store together in a single bucket"
         ^^^^^ 这个配置设置了一个 bucket 占用的最大的内存大小。 也是启动时修改， 我的疑惑同上。
        set_at: [ startup ]
        cpp_vartype: "std::int32_t"
        cpp_varname: "gTimeseriesBucketMaxSize"
        default: 128000 # 125KB
        validator: { gte: 1 }
    "timeseriesIdleBucketExpiryMemoryUsageThreshold":
        description: "The threshold for bucket catalog memory usage above which idle buckets will be
                      expired"
        ^^^^^^^^^^^ todo: 这个还不知道是干嘛的.
        set_at: [ startup ]
        cpp_vartype: "std::int32_t"
        cpp_varname: "gTimeseriesIdleBucketExpiryMemoryUsageThreshold"
        default:  104857600 # 100MB
        validator: { gte: 1 }

enums:
    BucketGranularity:
        description: "Describes a time-series collection's expected interval between subsequent
                      measurements"
        ^^^ 颗粒度，用来定义 bucket的时间颗粒度，这个参数可以影响 bucket的span seconds, 而 span seconds 则决定了 bucket里面存储的数据的时间范围.
        type: string
        values:
            Seconds: "seconds"
            Minutes: "minutes"
            Hours: "hours"

structs:
    TimeseriesOptions:
        description: "The options that define a time-series collection."
        ^^^^^^^^^ 用在创建表的语句里，用来创建 时序表的参数
        strict: true
        fields:
            timeField:
                description: "The name of the top-level field to be used for time. Inserted
                              documents must have this field, and the field must be of the BSON UTC
                              datetime type (0x9)"
                ^^^^^ 时间字段，插入文档必须包含这个字段，并且这个字段必须为 utc 时间类型.
                type: string
            metaField:
                description: "The name of the top-level field describing the series. This field is
                              used to group related data and may be of any BSON type. This may not
                              be \"_id\" or the same as 'timeField'."
                ^^^^^ 用于描述 文档的 meta 信息字段， 这个字段用来将相关的信息进行分组， 这个字段格式不限，只要是bson 字段就可以。 但不能使 _id 或者 timeFiled 字段这种区分度比较高的字段。
                type: string
                optional: true
            granularity:
                description: "Describes the expected interval between subsequent measurements"
                ^^^^^ 上面说的，表的颗粒度选择
                type: BucketGranularity
                default: Seconds
            bucketMaxSpanSeconds:
                description: "The maximum range of time values for a bucket, in seconds"
                ^^^^^ 定义了一个bucket的最大时间范围
                type: safeInt
                optional: true
                validator: { gte: 1 }

  ```


A minimally configured time-series collection is defined by providing the [timeField](timeseries.idl)
at creation. Optionally, a meta-data field may also be specified to help group
 measurements in the buckets. MongoDB also supports an expiration mechanism on measurements through
the `expireAfterSeconds` option.

一个最简易的 时序表的配置，就只提供一个 timeFiled 字段在创建的时候。 meta-data 字段作为可选字段，可以帮助更好的组织分类 时序数据. mongodb 支持超时机制，通过 expireAfterSeconds 的参数来实现的。 

A time-series collection `mytscoll` in the `mydb` database is represented in the [catalog](../catalog/README.md) by a
combination of a view and a system collection:
一个时序数据表 'mydb.mytscoll' 实际上是 catalog 通过 view 一个 system collecion来展现的。  

译者注：
  用户创建了时序表  mydb.mytscoll, 但实际上这个 mydb.mytscoll 是一个 视图(view), 真正的数据存储在了 mydb.system.bucket.mytscoll 这个表中， 这个表为了提升时序数据存储利用率和查询效率，采取了bucket数据组织方式跟用户插入的数据组织方式不一致。 所以又通过 view的方式，将用户对 mydb.mytscoll 的insert和query操作，转换为对 mydb.system.bucket.mytscoll 的操作。 
  注意，这里的 view(视图) 是一个可写视图.

* The view `mydb.mytscoll` is defined with the bucket collection as the source collection with
  certain properties:
    * Writes (inserts only) are allowed on the view. Every document inserted must contain a time field.
    * Querying the view implicitly unwinds the data in the underlying bucket collection to return
      documents in their original non-bucketed form.
        * The aggregation stage [$_internalUnpackBucket](../pipeline/document_source_internal_unpack_bucket.h) is used to
          unwind the bucket data for the view.
* mydb.mytscoll 作为一个视图，他的输入源是 bucket 表:
    * 视图支持写操作(只支持插入). 每个需要插入的文档都必须包含 time 字段. 
    * 查询这个 视图将会隐式 展开 bucket 表的数据，并返回为非bucket的格式。
      * aggregation 操作是使用 $_internalUnpackBucket 进行展开的.

* The system collection has the namespace `mydb.system.buckets.mytscoll` and is where the actual
  data is stored.
    * Each document in the bucket collection represents a set of time-series data within a period of time.
    * If a meta-data field is defined at creation time, this will be used to organize the buckets so that
      all measurements within a bucket have a common meta-data value.
    * Besides the time range, buckets are also constrained by the total number and size of measurements.
* 系统表 'mydb.system.buckets.mytscoll' 是真正存储数据的地方。
    * 每一个 bucket 表里的记录都包含了一段时间范围内的时序数据。 [cuixin: 译者注， bucket 组织数据是按照时间进行组织的]
    * 如果在创建的时序表的时候，制定了 meta-data 字段，那么时序表里所有的数据，都将使用这个 data-meta 字段.
    * bucket 除了受时间范围约束以外，还受bucket内数据条数和bucket总空间大小的约束。

## Bucket Collection Schema

```
{
    _id: <Object ID with time component equal to control.min.<time field>>,
    control: {
        // <Some statistics on the measurements such min/max values of data fields>
        version: 1,  // Version of bucket schema. Currently fixed at 1 since this is the
                     // first iteration of time-series collections.
        min: {
            <time field>: <time of first measurement in this bucket, rounded down based on granularity>,
            <field0>: <minimum value of 'field0' across all measurements>,
            <field1>: <maximum value of 'field1' across all measurements>,
            ...
        },
        max: {
            <time field>: <time of last measurement in this bucket>,
            <field0>: <maximum value of 'field0' across all measurements>,
            <field1>: <maximum value of 'field1' across all measurements>,
            ...
        },
        closed: <bool> // Optional, signals the database that this document will not receive any
                       // additional measurements.
    },
    meta: <meta-data field (if specified at creation) value common to all measurements in this bucket>,
    data: {
        <time field>: {
            '0', <time of first measurement>,
            '1', <time of second measurement>,
            ...
            '<n-1>': <time of n-th measurement>,
        },
        <field0>: {
            '0', <value of 'field0' in first measurement>,
            '1', <value of 'field0' in first measurement>,
            ...
        },
        <field1>: {
            '0', <value of 'field1' in first measurement>,
            '1', <value of 'field1' in first measurement>,
            ...
        },
        ...
    }
}
```

译者注： 补充一个真实的bucket的例子用于展示:
```bash
> db.system.buckets.weather.find().pretty()
{
        "_id" : ObjectId("60a30380e7c65e3582b69828"),
        "control" : {
                "version" : 1,
                "min" : {
                        "_id" : ObjectId("610b7b445d709040e3d32f36"),
                        "timestamp" : ISODate("2021-05-18T00:00:00Z"),
                        "temp" : 13,
                        "metadata" : [
                                {
                                        "sensorId" : 5578
                                },
                                {
                                        "type" : "temperature"
                                }
                        ]
                },
                "max" : {
                        "_id" : ObjectId("610b7b445d709040e3d32f36"),
                        "timestamp" : ISODate("2021-05-18T00:00:00Z"),
                        "temp" : 13,
                        "metadata" : [
                                {
                                        "sensorId" : 5578
                                },
                                {
                                        "type" : "temperature"
                                }
                        ]
                }
        },
        "data" : {
                "timestamp" : {
                        "0" : ISODate("2021-05-18T00:00:00Z")
                },
                "temp" : {
                        "0" : 13
                },
                "metadata" : {
                        "0" : [
                                {
                                        "sensorId" : 5578
                                },
                                {
                                        "type" : "temperature"
                                }
                        ]
                },
                "_id" : {
                        "0" : ObjectId("610b7b445d709040e3d32f36")
                }
        }
}
```

## Indexes

In order to support queries on the time-series collection that could benefit from indexed access
rather than collection scans, indexes may be created on the time, meta-data, and meta-data subfields
of a time-series collection. The index key specification provided by the user via `createIndex` will
be converted to the underlying buckets collection's schema.
为了更好的查询时序表，我们可以通过索引的方式访问而不是全表扫描。  所以可以创建在 time, meta-data, 和 meta-data 的子字段上。 用户通过 createIndex 可以指定索引的字段并将自动转化为 buckets 表的格式.

* The details for mapping the index specificiation between the time-series collection and the
  underlying buckets collection may be found in
  [timeseries_index_schema_conversion_functions.h](timeseries_index_schema_conversion_functions.h).
* 具体的 index 格式的在 时序库和bucket 库的映射方式， 可以在这里找到 [timeseries_index_schema_conversion_functions.h](timeseries_index_schema_conversion_functions.h).
```c++
    for (const auto& elem : timeseriesIndexSpecBSON) {
        if (elem.fieldNameStringData() == timeField) {
            ...
            // The time-series index on the 'timeField' is converted into a compound time index on
            // the buckets collection for more efficient querying of buckets.
            if (elem.number() >= 0) {
                builder.appendAs(
                    elem, str::stream() << timeseries::kControlMinFieldNamePrefix << timeField);
                builder.appendAs(
                    elem, str::stream() << timeseries::kControlMaxFieldNamePrefix << timeField);
            } else {
                builder.appendAs(
                    elem, str::stream() << timeseries::kControlMaxFieldNamePrefix << timeField);
                builder.appendAs(
                    elem, str::stream() << timeseries::kControlMinFieldNamePrefix << timeField);
            }
            ^^^^^ 对于 timeFiled 字段，换了个索引名字
            continue;
        }

        if (metaField) {
            if (elem.fieldNameStringData() == *metaField) {
                // The time-series 'metaField' field name always maps to a field named
                // timeseries::kBucketMetaFieldName on the underlying buckets collection.
                builder.appendAs(elem, timeseries::kBucketMetaFieldName);
                ^^^ 对于 meta 字段，如果索引名相等，那么也换个索引名字
                continue;
            }

            // Time-series indexes on sub-documents of the 'metaField' are allowed.
            if (elem.fieldNameStringData().startsWith(*metaField + ".")) {
                builder.appendAs(elem,
                                 str::stream()
                                     << timeseries::kBucketMetaFieldName << "."
                                     << elem.fieldNameStringData().substr(metaField->size() + 1));
                ^^^ 对于metaFiled 前缀的， 如果有， 那么也换个索引名字
                continue;
            }
        }
        ...


        if (elem.number() >= 0) {
            // For ascending key patterns, the { control.max.elem: 1, control.min.elem: 1 }
            // compound index is created.
            builder.appendAs(
                elem, str::stream() << timeseries::kControlMaxFieldNamePrefix << elem.fieldName());
            builder.appendAs(
                elem, str::stream() << timeseries::kControlMinFieldNamePrefix << elem.fieldName());
        } else if (elem.number() < 0) {
            // For descending key patterns, the { control.min.elem: -1, control.max.elem: -1 }
            // compound index is created.
            builder.appendAs(
                elem, str::stream() << timeseries::kControlMinFieldNamePrefix << elem.fieldName());
            builder.appendAs(
                elem, str::stream() << timeseries::kControlMaxFieldNamePrefix << elem.fieldName());
        }
        ^^^ 这里也换个名字， 注意，这里好像是联合索引

    }
```

Once the indexes have been created, they can be inspected through the `listIndexes` command or the
`$indexStats` aggregation stage. `listIndexes` and `$indexStats` against a time-series collection
will internally convert the underlying buckets collections' indexes and return time-series schema
indexes. For example, a `{meta: 1}` index on the underlying buckets collection will appear as
`{mm: 1}` when we run `listIndexes` on a time-series collection defined with `mm` for the meta-data
field.

索引一旦创建成功， 就可以用 listIndexes 命令或者 $indexStats aggregation stage 展示出来。 对 时间序列的listIndex 或者 $indexStats 都会内部转换为对于 underlying buckets collections 索引的的查询并且按照 时间序列表的索引方式进行返回。 具体， 当 {meta: 1} 在 underlying buckets 集合上时， 如果这个 时间序列的meta-data字段的名字为mm, 那么这个索引将会被按照 {mm: 1} 展示出来。

译者注: 给个例子
```bash
> db.system.buckets.foo2.getIndexes()
[ ]
> db.foo2.getIndexes()
[ ]
> db.foo2.createIndex({time: 1})
{
        "numIndexesBefore" : 0,
        "numIndexesAfter" : 1,
        "createdCollectionAutomatically" : false,
        "ok" : 1
}
> db.foo2.createIndex({time: -1})
{
        "numIndexesBefore" : 1,
        "numIndexesAfter" : 2,
        "createdCollectionAutomatically" : false,
        "ok" : 1
}
> db.foo2.getIndexes()
[
        {
                "v" : 2,
                "key" : {
                        "time" : 1
                },
                "name" : "time_1"
        },
        {
                "v" : 2,
                "key" : {
                        "time" : -1
                },
                "name" : "time_-1"
        }
]
> db.system.buckets.foo2.getIndexes()
[
        {
                "v" : 2,
                "key" : {
                        "control.min.time" : 1,
                        "control.max.time" : 1
                },
                "name" : "time_1"
        },
        {
                "v" : 2,
                "key" : {
                        "control.max.time" : -1,
                        "control.min.time" : -1
                },
                "name" : "time_-1"
        }
]

```


`dropIndex` and `collMod` (`hidden: <bool>`, `expireAfterSeconds: <num>`) are also supported on
time-series collections.

dropIndex 和 CollMode 也支持在 时间序列表上进行操作

Most index types are supported on time-series collections, including
[hashed](https://docs.mongodb.com/manual/core/index-hashed/),
[wildcard](https://docs.mongodb.com/manual/core/index-wildcard/),
[sparse](https://docs.mongodb.com/manual/core/index-sparse/),
[multikey](https://docs.mongodb.com/manual/core/index-multikey/), and
[indexes with collations](https://docs.mongodb.com/manual/indexes/#indexes-and-collation).

Index types that are not supported on time-series collections include
[geo](https://docs.mongodb.com/manual/core/2dsphere/),
[partial](https://docs.mongodb.com/manual/core/index-partial/),
[unique](https://docs.mongodb.com/manual/core/index-unique/), and
[text](https://docs.mongodb.com/manual/core/index-text/).

## BucketCatalog

In order to facilitate efficient bucketing, we maintain the set of open buckets in the
`BucketCatalog` found in [bucket_catalog.h](bucket_catalog.h). At a high level, we attempt to group
writes from concurrent writers into batches which can be committed together to minimize the number
of underlying document writes. A writer will insert each document in its input batch to the
`BucketCatalog`, which will return a handle to a `BucketCatalog::WriteBatch`. Upon finishing its
inserts, the writer will check each write batch. If no other writer has already claimed commit
rights to a batch, it will claim the rights and commit the batch itself; otherwise, it will set the
batch aside to wait on later. When it has checked all batches, the writer will wait on each
remaining batch to be committed by another writer.

为了更好的组织 bucket， 我们维护了一个 open buckets 的集合， BucketCatalog 可以在 bucket_catalog.h 中找到. 在上层层面， 我们通过对需要插入的数据进行组合和分组并并发写入到 write batch 这样来减少 underlying bucket 的写操作。写操作会将每个文档放到 bucketcatalog里面， 这将会返回一个 bucketcatalog::writebatch. 知道insert结束， 写操作会检查每个 write batch. 如果没有其他的写操作在提交 write batch的commit的话， 写操作自己将会commit这些write batch。否则的话， 这些操作将会等当前的写操作执行完成后，再提交。 [最后这句不知道怎么翻译]

[译者注: 这块的逻辑，提交跟其他write的交互关系还不太理解，需要再看一下代码]

Internally, the `BucketCatalog` maintains a list of updates to each bucket document. When a batch
is committed, it will pivot the insertions into the column-format for the buckets as well as
determine any updates necessary for the `control` fields (e.g. `control.min` and `control.max`).
内部的, BucketCatalog 为每个 bucket 维护了一个 update list. 当 bucket 提交， 这个update list 会被用来计算决定 列存格式下的 control 字段是否需要更新。例如 control.min 和  control.max 的字段. 

[译者注: 这个只保留本次的update，对于通用的crud来说，并不能保证列存的 control.min 和 control.max 的维护正确性。 但是对于时间序列来说，因为上层假设对这个表的写操作只有 insert, 所以可以通过 update 来保证control.min 和 control.mx 的正确性。 但是维护不了其他统计字段的正确性，比如方差之类的。不过暂时的时间序列不涉及这些东西]

Any time a bucket document is updated without going through the `BucketCatalog`, the writer needs
to call `BucketCatalog::clear` for the document or namespace in question so that it can update its
internal state and avoid writing any data which may corrupt the bucket format. This is typically
handled by an op observer, but may be necessary to call from other places.
任何时候对 bucket 的文档的更新操作都不需要经过 BucketCatalog, 写入需要为这个文档或者ns 调用 BucketCatalog::clear， 以便于更新内部状态避免写入数据影响了 bucket的format. 这个操作是为了 oplog observer 服务的，但我们也可以从其他地方调用它。



A bucket is closed either manually, by setting the optional `control.closed` flag, or automatically
by the `BucketCatalog` in a number of situations. If the `BucketCatalog` is using more memory than
it's given threshold (controlled by the server paramter
`timeseriesIdleBucketExpiryMemoryUsageThreshold`), it will start to close idle buckets. A bucket is
considered idle if it is open and it does not have any uncommitted measurements pending. The
`BucketCatalog` will also close a bucket if it contains more than the maximum number of measurments
(`timeseriesBucketMaxCount`), if it contains more than the maximum amount of data
(`timeseriesBucketMaxSize`), or if a new measurement would cause the bucket to span a greater
amount of time between it's oldest and newest time stamp than is allowed (currently hard-coded to
one hour).

bucket 可以被手段关闭，通过设置 control.closed 标志或者被 BucketCatalog 在下面情况下自动关闭。如果 BucketCatalog 使用了 给定限制的内存(通过 timeseriesIdleBucketExpiryMemoryUsageThreshold) 设置， 这将会关闭空闲的 buckets. 如果一个 bucket 处于打开状态，但是有没有任何没有提交的测量数据的时候，我们认为这个bucket 处于空闲状态。BucketCatalog 也会关闭 那些 内部数据超过最大限制的bucket，内部数据占用空间炒作限制，或者是新的 measurement 会导致bucket 占用较长时间跨度的 bucket。目前这个较长时间的跨度为 1 个小时。

The first time a write batch is committed for a given bucket, the newly-formed document is
inserted. On subsequent batch commits, we perform an update operation. Instead of generating the
full document (a so-called "classic" update), we create a DocDiff directly (a "delta" or "v2"
update).

第一个bucket的写记录时候insert， 其他后续的写操作提交的时候， 我们使用 update 操作。 为了避免产生巨大的 全文档(经典的update)， 我们创建一个 doc diff 。 

# Granularity

The `granularity` option for a time-series collection can be set at creation to be 'seconds',
'minutes' or 'hours'. A later `collMod` operation can change the option from 'seconds' to 'minutes'
or from 'minutes' to 'hours', but no other transitions are currently allowed. This parameter is
intended to convey the rough time period between measurements in a given time-series, and is used to
tweak other internal parameters that affect bucketing.

granularity 选项是 time-series 表在创建的时候可以选择的。这个选项可以使 'sceonds', 'mintues', 'hours'. collMod 命令可以将这个选项进行升级， 但是不能降级。 这个参数用来表示 周期内 大致的时间范围， 用来调整内部内部可以影响bucket的一些参数。

The maximum span of time that a single bucket is allowed to cover is controlled by `granularity`,
with the maximum span being set to one hour for 'seconds', 24 hours for 'minutes', and 30 days
for 'hours'.

bucket的最大跨度时间就可以被 granularity 影响。 如果设置为 seconds, 那么最大时间就是一个小时。如果设置为分钟最大时间就是一天，如果设置为小时，最大时间超时就是为一个月。

When a new bucket is opened by the `BucketCatalog`, the timestamp component of its `_id`, and
equivalently the value of its `control.min.<time field>`, will be taken from the first measurement
inserted to the bucket and rounded down based on the `granularity`. It will be rounded down to the
nearest minute for 'seconds', the nearest hour for 'minutes', and the nearest day for 'hours'. This
rounding may not be perfect in the case of leap seconds and other irregularities in the calendar,
and will generally be accomplished by basic modulus aritmetic operating on the number of seconds
since the epoch, assuming 60 seconds per minute, 60 minutes per hour, and 24 hours per day.

# References
See:
[MongoDB Blog: Time Series Data and MongoDB: Part 2 - Schema Design Best Practices](https://www.mongodb.com/blog/post/time-series-data-and-mongodb-part-2-schema-design-best-practices)

# Glossary
**bucket**: A group of measurements with the same meta-data over a limited period of time.

**bucket collection**: A system collection used for storing the buckets underlying a time-series
collection. Replication, sharding and indexing are all done at the level of buckets in the bucket
collection.

**measurement**: A set of related key-value pairs at a specific time.

**meta-data**: The key-value pairs of a time-series that rarely change over time and serve to
identify the time-series as a whole.

**time-series**: A sequence of measurements over a period of time.

**time-series collection**: A collection type representing a writable non-materialized view that
allows storing and querying a number of time-series, each with different meta-data.
