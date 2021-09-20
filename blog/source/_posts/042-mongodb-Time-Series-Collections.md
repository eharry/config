---
title: 042-mongodb-Time-Series-Collections
date: 2021-08-05 13:13:49
tags:
---



Mongodb 5.0 引入了 Time-Series-Collections， 具体官方文档看这里： https://docs.mongodb.com/manual/core/timeseries-collections/

<!--more-->

* 创建 Time Series 表

  ```bash
  > db.createCollection("weather", { timeseries: { timeField: "timestamp" } } )
  { "ok" : 1 }
  ```

* show collections 查看

  ```bash
  > show collections
  system.buckets.weather
  system.views
  weather
  ```

* 创建 出来的 weather 是 视图，真正的表是  system.buckets.weather

  ```bash
  > db.system.views.find()
  { "_id" : "test.weather", "viewOn" : "system.buckets.weather", "pipeline" : [ { "$_internalUnpackBucket" : { "timeField" : "timestamp", "bucketMaxSpanSeconds" : 3600, "exclude" : [ ] } } ] }
  
  ```

<!--more-->

* 为什么需要一个视图在这里？ 

  * 组内大神给的解释， 因为客户插入的数据和真实数据不一致， 需要用 view 来展示 插入数据的样子.
  * 我倒是觉得，因为时序数据一般数据量偏小，如果一条记录存一个时序数据， 无效字段占用太多， 倒不如 group起来， 增加信息存储比率，也进一步提高存储利用率。 
  * 如果采用原生的方式，加time索引全量的字段，也能存储， 就是存储的信息利用率不高

* $_internalUnpackBucket 是什么?

  * 用于将 bucket 里面的数据转化为 view 表示的数据的算子

  ```c++
  document_source_internal_unpack_bucket.h
  DocumentSourceInternalUnpackBucket
  DocumentSource::GetNextResult DocumentSourceInternalUnpackBucket::doGetNext() {                        
      tassert(5521502, "calling doGetNext() when '_sampleSize' is set is disallowed", !_sampleSize);     

      // Otherwise, fallback to unpacking every measurement in all buckets until the child stage is      
      // exhausted.                                                                                      
      if (_bucketUnpacker.hasNext()) {                                                                   
          return _bucketUnpacker.getNext();                                                              
      }                                                                                                  

      auto nextResult = pSource->getNext();                                                              
      if (nextResult.isAdvanced()) {                                                                     
          auto bucket = nextResult.getDocument().toBson();                                               
          _bucketUnpacker.reset(std::move(bucket));                                                      
          uassert(5346509,                                                                               
                  str::stream() << "A bucket with _id "                                                  
                  << _bucketUnpacker.bucket()[timeseries::kBucketIdFieldName].toString()   
                  << " contains an empty data region",                                     
                  _bucketUnpacker.hasNext());                                                            
          return _bucketUnpacker.getNext();                                                              
      }                                                                                                  

      return nextResult;                                                                                 
  }                                                                                                      

  ```

  * 这里， 优先从 _bucketUnpacker 里面拿， 如果 _bucketUnpacker 没有，那么从 source里面那。 具体到 真正的调用， _bucketUnpacker 就是从 bucket文档里拿数据， source 的next， 就是从bucket里拿一个文档。
  * 在 _bucketUnpacker 会对 bucket 文档里的每个 array element 进行遍历读取，然后转换成 view的数据，进行返回.

  ```c++
  Document BucketUnpacker::getNext() {
    tassert(5521503, "'getNext()' requires the bucket to be owned", _bucket.isOwned());
    tassert(5422100, "'getNext()' was called after the bucket has been exhausted", hasNext());

    auto measurement = MutableDocument{};
    auto&& timeElem = _timeFieldIter->next();
    if (_includeTimeField) {
        measurement.addField(_spec.timeField, Value{timeElem});
    }

    // Includes metaField when we're instructed to do so and metaField value exists.
    if (_includeMetaField && _metaValue) {
        measurement.addField(*_spec.metaField, Value{_metaValue});
    }

    auto& currentIdx = timeElem.fieldNameStringData();
    for (auto&& [colName, colIter] : _fieldIters) {
        if (auto&& elem = *colIter; colIter.more() && elem.fieldNameStringData() == currentIdx) {
            measurement.addField(colName, Value{elem});
            colIter.advance(elem);
        }
    }

    // Add computed meta projections.
    for (auto&& name : _spec.computedMetaProjFields) {
        measurement.addField(name, Value{_computedMetaProjections[name]});
    }

    if (_spec.includeBucketIdAndRowIndex) {
        MutableDocument nestedMeasurement{};
        nestedMeasurement.addField("bucketId", Value{_bucket[timeseries::kBucketIdFieldName]});
        int rowIndex;
        uassertStatusOK(NumberParser()(currentIdx, &rowIndex));
        nestedMeasurement.addField("rowIndex", Value{rowIndex});
        nestedMeasurement.addField("rowData", measurement.freezeToValue());
        return nestedMeasurement.freeze();
    }
    return measurement.freeze();
  }

  ```

  * 可以看出， 这里的转换还是很简单的. metafiled 是 唯一的，直接填充， 后面的文档数据， 将从 _fieldIters 直接获取。
  * 所有的 index 从timeField 直接获取，然后应用到 每项字段上。 注意是按照 name 进行匹配的，而不是通过数组的index获取，因为要考虑到有些字段没有的情况.

* insert 文档

  ```bash
  > db.weather.insert({ "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 13, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] })
  WriteResult({ "nInserted" : 1 })
  ```

  ```bash
  > db.weather.find()
  { "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 13, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ], "_id" : ObjectId("610b7b445d709040e3d32f36") }
  ```

  ```bash
  > db.system.buckets.weather.find()
  { "_id" : ObjectId("60a30380e7c65e3582b69828"), "control" : { "version" : 1, "min" : { "_id" : ObjectId("610b7b445d709040e3d32f36"), "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 13, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] }, "max" : { "_id" : ObjectId("610b7b445d709040e3d32f36"), "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 13, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] } }, "data" : { "timestamp" : { "0" : ISODate("2021-05-18T00:00:00Z") }, "temp" : { "0" : 13 }, "metadata" : { "0" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] }, "_id" : { "0" : ObjectId("610b7b445d709040e3d32f36") } } }
  
  ```

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

  * 可以看出 bucket的存储格式，还是跟原始格式有一定区别的， 不仅仅有 min 和  max 字段，在 data字段上，也引入 序号， 不难想象，如果bucket里面有两条数据， 那么 就应该有1的序号了

* 在插入一条记录

  ```bash
  db.weather.insert({ "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 14, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] })
  ```

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
                          "_id" : ObjectId("610b7c6e5d709040e3d32f37"),
                          "timestamp" : ISODate("2021-05-18T00:00:00Z"),
                          "temp" : 14,
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
                          "0" : ISODate("2021-05-18T00:00:00Z"),
                          "1" : ISODate("2021-05-18T00:00:00Z")
                  },
                  "temp" : {
                          "0" : 13,
                          "1" : 14
                  },
                  "metadata" : {
                          "0" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ],
                          "1" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ]
                  },
                  "_id" : {
                          "0" : ObjectId("610b7b445d709040e3d32f36"),
                          "1" : ObjectId("610b7c6e5d709040e3d32f37")
                  }
          }
  }
  
  ```

  * 可以看出，再插入一条纪录后， min和max的值均有所编号， 并且在data字段中，包含了两个值。

* 如果插入一个具有更多格式的数据，是什么表现呢？

  ```bash
  > db.weather.insert({ "timestamp" : ISODate("2021-05-18T00:00:00Z"), "temp" : 14, "ext1": 1, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] })
  WriteResult({ "nInserted" : 1 })
  ```

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
                          ],
                          "ext1" : 1
                  },
                  "max" : {
                          "_id" : ObjectId("610b7d285d709040e3d32f38"),
                          "timestamp" : ISODate("2021-05-18T00:00:00Z"),
                          "temp" : 14,
                          "metadata" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ],
                          "ext1" : 1
                  }
          },
          "data" : {
                  "timestamp" : {
                          "0" : ISODate("2021-05-18T00:00:00Z"),
                          "1" : ISODate("2021-05-18T00:00:00Z"),
                          "2" : ISODate("2021-05-18T00:00:00Z")
                  },
                  "temp" : {
                          "0" : 13,
                          "1" : 14,
                          "2" : 14
                  },
                  "metadata" : {
                          "0" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ],
                          "1" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ],
                          "2" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ]
                  },
                  "_id" : {
                          "0" : ObjectId("610b7b445d709040e3d32f36"),
                          "1" : ObjectId("610b7c6e5d709040e3d32f37"),
                          "2" : ObjectId("610b7d285d709040e3d32f38")
                  },
                  "ext1" : {
                          "2" : 1
                  }
          }
  }
  
  ```

  * 可见，额外字段是不影响分组 bucket的， 应该说只有 时间会影响bucket 分组

* 那么一个bucket的数组数据会有多大的？

  ```bash
  > for(var i = 0; i < 3000; i++) { db.weather.insert({ "timestamp" : ISODate("2021-05-19T00:00:00Z"), "temp" : i, "metadata" : [ { "sensorId" : 5578 }, { "type" : "temperature" } ] })}
  WriteResult({ "nInserted" : 1 })
  ```

  ```bash
  > db.system.buckets.weather.find({},{_id: 1})
  { "_id" : ObjectId("60a30380e7c65e3582b69828") }
  { "_id" : ObjectId("60a45500e7c65e3582b6984d") }
  { "_id" : ObjectId("60a45500e7c65e3582b69c36") }
  { "_id" : ObjectId("60a45500e7c65e3582b6a01f") }
  ```

  * 一开始有一个， 后来换了时间后， 插入3000条，多了三个bucket， 那基本能表示 1000条是一个bucket的上限， 即便是 时间一致的情况下.

  ```bash
  > db.system.buckets.weather.find({},{"control.min": 1}).pretty()
  {
          "_id" : ObjectId("60a30380e7c65e3582b69828"),
          "control" : {
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
                          ],
                          "ext1" : 1
                  }
          }
  }
  {
          "_id" : ObjectId("60a45500e7c65e3582b6984d"),
          "control" : {
                  "min" : {
                          "_id" : ObjectId("610b7deb5d709040e3d32f39"),
                          "timestamp" : ISODate("2021-05-19T00:00:00Z"),
                          "temp" : 0,
                          "metadata" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ]
                  }
          }
  }
  {
          "_id" : ObjectId("60a45500e7c65e3582b69c36"),
          "control" : {
                  "min" : {
                          "_id" : ObjectId("610b7dec5d709040e3d33321"),
                          "timestamp" : ISODate("2021-05-19T00:00:00Z"),
                          "temp" : 1000,
                          "metadata" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ]
                  }
          }
  }
  {
          "_id" : ObjectId("60a45500e7c65e3582b6a01f"),
          "control" : {
                  "min" : {
                          "_id" : ObjectId("610b7ded5d709040e3d33709"),
                          "timestamp" : ISODate("2021-05-19T00:00:00Z"),
                          "temp" : 2000,
                          "metadata" : [
                                  {
                                          "sensorId" : 5578
                                  },
                                  {
                                          "type" : "temperature"
                                  }
                          ]
                  }
          }
  }
  
  ```

  * 上面打印出了 min， 也表明 每 1000条作为一个分组的.

* 时间一致的情况下， min和max是如何比较大小的？为什么有的记录是min，有的记录是max

  * 就目前测试结果来看， 应该是按照时间和插入序(原生_id)进行比较的。待定。

* insert 相关代码分析:

  * 写函数的入口从 _performTimeseriesWrites 进入
  * 然后会调用 _performOrderedTimeseriesWrites 
  * 然后调用 _performOrderedTimeseriesWritesAtomically

  ```c++
          bool _performOrderedTimeseriesWritesAtomically(OperationContext* opCtx,
                                                         std::vector<BSONObj>* errors,
                                                         boost::optional<repl::OpTime>* opTime,
                                                         boost::optional<OID>* electionId,
                                                         bool* containsRetry) const {
              auto [batches, stmtIds, numInserted] = _insertIntoBucketCatalog(
                  opCtx, 0, request().getDocuments().size(), {}, errors, containsRetry);
  
              hangTimeseriesInsertBeforeCommit.pauseWhileSet();
  
              if (!_commitTimeseriesBucketsAtomically(
                      opCtx, &batches, std::move(stmtIds), errors, opTime, electionId)) {
                  return false;
              }    
  
              _getTimeseriesBatchResults(opCtx, batches, 0, errors, opTime, electionId);
  
              return true;
          }    
  
  ```

  * 上面函数中，有两个部分，第一个部分，用于生成 writebatch， 第二个部分用于提交 writebatch

  * 提交 writebatch， 就是将写入转换为 普通的insert和update， 然后写入数据库， 跟原始流程差别不大， 

  * 主要看第一部分， 如何根据 用户数据，对应到 相关bucket的。

  * BucketCatalog 类，主要用于 进行 Time-Series 相关操作, 从 get 函数就可以知道，这个 对象是全局唯一的

    ```c++
    BucketCatalog& BucketCatalog::get(ServiceContext* svcCtx) {
        return getBucketCatalog(svcCtx);
    }
    
    BucketCatalog& BucketCatalog::get(OperationContext* opCtx) {                                                                      
        return get(opCtx->getServiceContext());
    }
    ```

    * 所有的 bucket 都保存在 bucket catalog 里面， 成员变量是  _allBuckets 

      ```c++
      // All buckets currently in the catalog, including buckets which are full but not yet committed.
      stdx::unordered_set<std::unique_ptr<Bucket>> _allBuckets;
      
      ```

    * 所有的 open bucket 都保存在 _openBuckets 里面，

      ```c++
          // The current open bucket for each namespace and metadata pair.
          stdx::unordered_map<BucketKey, Bucket*, BucketHasher, BucketEq> _openBuckets;      
      ```

      * _openBuckets 有三个地方可以插入

        ```c++
        BucketCatalog::Bucket* BucketCatalog::_allocateBucket(const BucketKey& key,
                                                              const Date_t& time,
                                                              const TimeseriesOptions& options,
                                                              ExecutionStats* stats,
                                                              bool openedDuetoMetadata) {
            _expireIdleBuckets(stats);
        
            auto [it, inserted] = _allBuckets.insert(std::make_unique<Bucket>());
            Bucket* bucket = it->get();
            _setIdTimestamp(bucket, time, options);
            _openBuckets[key] = bucket;                                                                                                                                                          
        
            if (openedDuetoMetadata) {
                stats->numBucketsOpenedDueToMetadata.fetchAndAddRelaxed(1);
            }
        
            return bucket;
        }   
        ```

        ```c++
        BucketCatalog::BucketState BucketCatalog::BucketAccess::_findOpenBucketThenLockAndStoreKey(
            const HashedBucketKey& normalizedKey,
            const HashedBucketKey& nonNormalizedKey,
            BSONObj nonNormalizedMetadata) {
            invariant(!isLocked());
            {
                auto lk = _catalog->_lockExclusive();
                auto it = _catalog->_openBuckets.find(normalizedKey);
                if (it == _catalog->_openBuckets.end()) {
                    // Bucket does not exist.
                    return BucketState::kCleared;
                }
        
                _bucket = it->second;
                _acquire();
        
                // Store the non-normalized key if we still have free slots
                if (_bucket->_nonNormalizedKeyMetadatas.size() <
                    _bucket->_nonNormalizedKeyMetadatas.capacity()) {
                    auto [_, inserted] =
                        _catalog->_openBuckets.insert(std::make_pair(nonNormalizedKey, _bucket));
                    if (inserted) {
                        _bucket->_nonNormalizedKeyMetadatas.push_back(nonNormalizedMetadata);
                        // Increment the memory usage to store this key and value in _openBuckets
                        _bucket->_memoryUsage += nonNormalizedKey.key->ns.size() +
                            nonNormalizedMetadata.objsize() + sizeof(_bucket);
                    }
                }
            }
        
            return _confirmStateForAcquiredBucket();
        }   
        ```

        ```c++
        void BucketCatalog::BucketAccess::_create(const HashedBucketKey& normalizedKey,
                                                  const HashedBucketKey& nonNormalizedKey,
                                                  bool openedDuetoMetadata) {
            invariant(_options);
            _bucket =
                _catalog->_allocateBucket(normalizedKey, *_time, *_options, _stats, openedDuetoMetadata);
            _catalog->_openBuckets[nonNormalizedKey] = _bucket;                                                                                                                                  
            _bucket->_nonNormalizedKeyMetadatas.push_back(nonNormalizedKey.key->metadata.toBSON());
            _acquire();
        }
        ```

        * _allocateBucket 只在 create 函数中被调用， 所以每次 _create, 对于一个 bucket， 在 openBuckets 里都会有两个key 进行对应。 分别是 normalizedKey 和 nonNormalizedKey。 为什么这么设计， 暂时不得而知.

        * 第二种情况， 当 nonNormalizedKey 的容量低于限制时, 我们会将 nonNormalizedKey 也存入 _allocateBucket 中。

          * why do this? 

            ```bash
            SERVER-55942 Store un-normalized bucket keys in the open buckets map.
            
            Lazily normalize key on insert when un-normalized is not found.
            Also use precomputed bucket hashes when modifying the bucket catalog under exclusive lock.
            ```

        * normalizedKey 和 nonNormalizedKey 的区别是什么？ 用法有什么差别？

          * 还是不知道有什么差别，但是可以知道的是，最终的查询用不到这些key， 这个 bucketkey 只适用于 active bucket 使用的。

          * 组内大神给的解释
            * normalizedKey 就是对 nonNormalizedKey 进行的一个排序，做到了一个归一化。
            * 对于 客户插入数据来说， 假设有 a, b, c三个字段， 那么可能出现的顺序就有 6种,
            * nonNormalizedKey 可以是这六种的任意一种， 而 normalizedKey 只能是字母序，也就是 abc 这一种，
            * 所以 如果 都用 normalizedKey 作为 bucketkey ， 那么是可以一定能把相同出现的记录放到一个bucket里的。
            * 但是 排序操作是个耗时操作， 所以， mongodb 也提供了 一定数量的 nonNormalizedKey 也可以定位到这个 bucket里， 这会提高性能，并降低一定程度的CPU消耗。

    * BucketKey

      * auto key = BucketKey{ns, BucketMetadata{metadata, comparator}}; 

      * 很明显， 这个key 并不是唯一的， 每次插入的数据，基本上都是在一个key上。

      * 如果只跟ns相关， 那么每次插入的时候，时间不一致的记录，也会存在一个bucket里面吗？那岂不是实现有问题。这个可以通过改一下代码测试验证。

        ```bash
        assert.commandWorked(db.createCollection("foo1", {timeseries: {timeField: "time"}}));
        assert.commandWorked(db.createCollection("foo2", {timeseries: {timeField: "time"}}));                        
        const coll1 = db.getCollection("foo1");                                                                      
        const coll2 = db.getCollection("foo2");
            
        for (let i = 0; i < 2000; i++) {                                                                             
              assert.commandWorked(coll1.insert({
                  measurement: "cpu",
                  time: ISODate("2021-05-18T00:00:00Z"),
                  "a": i
              }));
              assert.commandWorked(coll1.insert({
                  measurement: "cpu",
                  time: ISODate("2021-05-19T00:00:00Z"),
                  "b": i
              }));
        }       
        for (let i = 0; i < 2000; i++) {
              assert.commandWorked(coll2.insert({
                  measurement: "cpu",
                  time: ISODate("2021-05-18T00:00:00Z"),
                  "a": i
              }));  
        }           
        for (let i = 0; i < 2000; i++) {
              assert.commandWorked(coll2.insert({
                  measurement: "cpu",
                  time: ISODate("2021-05-19T00:00:00Z"),
                  "b": i
              }));
        }   
        
        ```

        ```bash
        > show collections
        foo1
        foo2
        system.buckets.foo1
        system.buckets.foo2
        system.views
        > db.system.buckets.foo1.count()
        4000
        > db.system.buckets.foo2.count()
        4
        
        ```

        * 看到上面的例子，大概理解了为什么 整个 时间序列表的工作逻辑了

          * 首先， 插入都会放到 bucket里，  根据一定的规则，保证 bucket 里面的数据符合一定的关系

            * bucket 数据不能太多，
            * bucket 数据量不能太大
            * bucket 里面存储的时间差别不能太大， 这个体现为创建表的时候， 使用的参数 granularity， 颗粒度的意思。
            * bucket 里面的时间插入时必须是递增的。
              * 后面有解释原因，就是为了 保证 _id 的时间可用性，用 _id 表示 bucket的最小时间.

          * 这些逻辑对应的代码，是这个函数: 

            ```c++
                auto isBucketFull = [&](BucketAccess* bucket) -> bool {
                    if ((*bucket)->_numMeasurements == static_cast<std::uint64_t>(gTimeseriesBucketMaxCount)) {
                        stats->numBucketsClosedDueToCount.fetchAndAddRelaxed(1);
                        return true;
                    }
                    if ((*bucket)->_size + sizeToBeAdded >
                        static_cast<std::uint64_t>(gTimeseriesBucketMaxSize)) { 
                        stats->numBucketsClosedDueToSize.fetchAndAddRelaxed(1);
                        return true;
                    }
                    auto bucketTime = (*bucket).getTime();
                    if (time - bucketTime >= Seconds(*options.getBucketMaxSpanSeconds())) {
                        stats->numBucketsClosedDueToTimeForward.fetchAndAddRelaxed(1);
                        return true;
                    }
                    if (time < bucketTime) {
                        stats->numBucketsClosedDueToTimeBackward.fetchAndAddRelaxed(1);
                        return true;
                    }
                    return false;
                };
            ```

            * 并且系统中，只能同时存在一个 ns和metadata 组成的key的bucket， 这也就意味着一旦一个bucket 被判断为 full，写了下去，下次就不会再被更改了。

        * 具体写入操作
          
          * 在得到bucket后， 会拿到 bucket 的activeBatch 方法将数据写入 writebatch里, 
          * timeseries 预期客户是使用 inserts muti docs 这个方式去插入数据的， 所以这里会有一个 batch， 但如果客户是单条 insert， 这里的这个batch 就没有任何作用。 
          * 这里的batch 也没有任何数据缓存的功能.
          * 写入操作这里区分了 bucket以后， 整个特殊的写入数据流程就结束了， 后面的流程就跟普通的写入基本类似了。 


        * 既然 bucket 之间并没有 时间递增等强制约束， 那么在具体查询某个时间的数据的时候， timeseries 又是如何定位到具体的某个bucket的呢？
          
          * 对于带有时间戳的查询， 应该是可以根据时间戳算出具体的 bucket 表的 下划线 _id 的， 然后可以缩减范围.
          * 对于不带时间戳的查询， 那就使用 bucket 表 doc的 control 字段来加速表的遍历， 但仍是一项耗时操作，这应该是不被建议采用的。 
          * 时序数据库的查询应该带有时间信息.
    
        * 那么 bucket 表中 doc 的 _id  跟时间是如何关联的呢?
    
          * 着重看这个函数 makeTimeseriesInsertDocument
          * doc 的id是 OID， 也就是 object id, 
    
          ```c++
 *               4 byte timestamp    5 byte process unique   3 byte counter
 *             |<----------------->|<---------------------->|<------------->                                                                                                                                   * OID layout: [----|----|----|----|----|----|----|----|----|----|----|----]
 *             0                   4                   8                   12
          ```
          * 其中，高四位为 timestamp, 
          * 这个id 在每次 申请新的 bucket 的时候， 会设置第一条 doc的timestamp 为bucket id的timestamp， 这也解释了为什么 bucket里面的 doc的ts必须要是递增的。
          * 所以如果带有时间顺序后， 这个id可以表示时间信息， 这样在具体查询数据的时候， 就可以极大的缩减数据范围进行全表查询了。
          * 例子如下:
            * 上面给的例子里有两个 时间:
              * 2021-05-18T00:00:00Z:  1621238400  0x60A22280
              * 2021-05-19T00:00:00Z:  1621324800  0x60A37400
            
            ```bash
            "winningPlan" : {
                "stage" : "COLLSCAN",
                "filter" : {
                    "$and" : [
                    {
                        "_id" : {
                            "$lte" : ObjectId("60a30380ffffffffffffffff")
                        }
                    },
                    {
                        "_id" : {
                            "$gte" : ObjectId("60a2f5700000000000000000")
                        }
                    },
                    ...
          ```



​            

