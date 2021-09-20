---
title: 044-mongodb-PlanStage
date: 2021-08-29 17:37:04
tags:
---

文章简要介绍了 mongodb  plane stage 的基础概念, 主要是个人查看代码后的记录.

<!--more-->

### mongodb planstage

* planstage 简要流程 见代码注释


```c++
/**
 * A PlanStage ("stage") is the basic building block of a "Query Execution Plan."  A stage is
 * the smallest piece of machinery used in executing a compiled query.  Stages either access
 * data (from a collection or an index) to create a stream of results, or transform a stream of
 * results (e.g. AND, OR, SORT) to create a stream of results.
   [
   planstage 是执行复杂查询的基本执行单元. 
   stages 可以通过 访问表和索引来创建一个结果流, 
   或者将一个结果流转换为另一个结果流(例如 AND, OR, SORT). 
   ]
 * Stages have zero or more input streams but only one output stream.  Data-accessing stages are
 * leaves and data-transforming stages have children.  Stages can be connected together to form
 * a tree which is then executed (see plan_executor.h) to solve a query.
   [
   stages 可以有0或者多个输入，但是只能有一个输出结果流.(这就长得像一颗树了). 
   访问数据的的stage 是叶子节点, 做数据转换的stage通常有子节点。
   stage 被连接起来像一个树形结构，然后执行查询操作.
   ]
 *
 * A stage's input and output are each typed.  Only stages with compatible types can be
 * connected.
 *
 * All of the stages of a QEP share a WorkingSet (see working_set.h).  Data source stages
 * allocate a slot in the WorkingSet, fill the slot with data, and return the ID of that slot.
 * Subsequent stages fetch a WorkingSetElement by its ID and operate on the enclosed data.
   [
     所有的stage，共享一个 workingSet. 读取数据的stage，负责在 workingSet 里面申请一个 slot， 并将数据
     填充进 slot, 并返回  slot it.  后续的 stage，负责通过id读取这个数据，并操作它.
   ]
 *
 * Stages do nothing unless work() is called.  work() is a request to the stage to consume one
 * unit of input.  Some stages (e.g. AND, SORT) require many calls to work() before generating
 * output as they must consume many units of input.  These stages will inform the caller that
 * they need more time, and work() must be called again in order to produce an output.
   [
   work() 函数是 stage用来具体工作的函数。 work() 函数用于负责消费一个 单位的 input. 有些 stages(and, sort) 可能需要 调用
   多次 work 函数消费多个 input 单位 来产生一个output.  这些stage会通知 他的调用者， 需要更懂的时间， 然后继续调用 work()
   函数来产生一个 output.
   ]
 *
 * Every stage of a query implements the PlanStage interface.  Queries perform a unit of work
 * and report on their subsequent status; see StatusCode for possible states.  Query results are
 * passed through the WorkingSet interface; see working_set.h for details.

   [
     每个 stage 都实现了 PlanStage 的接口. 
   ]
 *
 * All synchronization is the responsibility of the caller.  Queries must be told to yield with
 * saveState() if any underlying database state changes.  If saveState() is called,
 * restoreState() must be called again before any work() is done.
 *
 * If an error occurs at runtime (e.g. we reach resource limits for the request), then work() throws
 * an exception. At this point, statistics may be extracted from the execution plan, but the
 * execution tree is otherwise unusable and the plan must be discarded.
 *
 * Here is a very simple usage example:
 *
 * WorkingSet workingSet;
 * PlanStage* rootStage = makeQueryPlan(&workingSet, ...);
 * while (!rootStage->isEOF()) {
 *     WorkingSetID result;
 *     switch(rootStage->work(&result)) {
 *     case PlanStage::ADVANCED:
 *         // do something with result
 *         WorkingSetMember* member = workingSet.get(result);
 *         cout << "Result: " << member->obj << std::endl;
 *         break;
 *     case PlanStage::IS_EOF:
 *         // All done.  Will fall out of while loop.
 *         break;
 *     case PlanStage::NEED_TIME:
 *         // Need more time.
 *         break;
 *     }
 *
 *     if (shouldYield) {
 *         // Occasionally yield.
 *         stage->saveState();
 *         // Do work that requires a yield here (execute other plans, insert, delete, etc.).
 *         stage->restoreState();
 *     }
 * }
 */
```

* planstage 不仅实现了接口，还实现了一部分 stage true 遍历的过程， 比如 saveState, restoreState, detachFromOperationContext, reattachToOperationContext, 就是 先 child 后自己的逻辑实现.
* saveState 和 restoreState 是一对相反的操作，用于 Yielding 前后保存状态的。 着重看下几个stage 实现 saveState 的例子:
  * TextOrStage::doSaveStateRequiresCollection, FetchStage::doSaveStateRequiresCollection and CollectionScan::doSaveStateRequiresCollection 直接使用的是 cursor的 save 功能.
  * MultiIteratorStage::doSaveStateRequiresCollection 使用的也是 cursor 的 save 功能， 这里多个 cursor， 在这个stage 每个 cursor 叫iterator.
  * RequiresIndexStage::doSaveStateRequiresCollection 使用的 index的save state，内部也是使用 index的 cursor 的save操作，所以基本上所有的 savestate， 都是使用了 record store 的 cursor的save操作.

* StageType
  * 虽然这个叫 type， 实际上就是 stageid, 因为这个类型很细，基本上就是每一类.

  ```c++
  // These map to implementations of the PlanStage interface, all of which live in db/exec/
  
   enum StageType {
      STAGE_AND_HASH,
      STAGE_AND_SORTED,
      STAGE_CACHED_PLAN,
      STAGE_COLLSCAN,
  
      // A virtual scan stage that simulates a collection scan and doesn't depend on underlying
      // storage.
      STAGE_VIRTUAL_SCAN,
      
      // This stage sits at the root of the query tree and counts up the number of results
      // returned by its child.
      STAGE_COUNT,
      
      // If we're running a .count(), the query is fully covered by one ixscan, and the ixscan is
      // from one key to another, we can just skip through the keys without bothering to examine
      // them.
      STAGE_COUNT_SCAN,
      
      STAGE_DELETE,
      
      // If we're running a distinct, we only care about one value for each key.  The distinct
      // scan stage is an ixscan with some key-skipping behvaior that only distinct uses.
      STAGE_DISTINCT_SCAN,
      
      STAGE_ENSURE_SORTED,
      
      STAGE_EOF,
      
      STAGE_FETCH,
      
      // The two $geoNear impls imply a fetch+sort and must be stages.
      STAGE_GEO_NEAR_2D,
      STAGE_GEO_NEAR_2DSPHERE,
      
      STAGE_IDHACK,
      
      STAGE_IXSCAN,
      STAGE_LIMIT,
      
      STAGE_MOCK,
      
      // Implements iterating over one or more RecordStore::Cursor.
      STAGE_MULTI_ITERATOR,
      
      STAGE_MULTI_PLAN,
      STAGE_OR,
      
      // Projection has three alternate implementations.
      STAGE_PROJECTION_DEFAULT,
      STAGE_PROJECTION_COVERED,
      STAGE_PROJECTION_SIMPLE,
      
      STAGE_QUEUED_DATA,
      STAGE_RECORD_STORE_FAST_COUNT,
      STAGE_RETURN_KEY,
      STAGE_SAMPLE_FROM_TIMESERIES_BUCKET,
      STAGE_SHARDING_FILTER,
      STAGE_SKIP,
      
      STAGE_SORT_DEFAULT,
      STAGE_SORT_SIMPLE,
      STAGE_SORT_KEY_GENERATOR,
      
      STAGE_SORT_MERGE,
      STAGE_SUBPLAN,
      
      // Stages for running text search.
      STAGE_TEXT_OR,
      STAGE_TEXT_MATCH,
      
      // Stage for choosing between two alternate plans based on an initial trial period.
      STAGE_TRIAL,
      
      STAGE_UNKNOWN,
      
      STAGE_UNPACK_TIMESERIES_BUCKET,
      
      STAGE_UPDATE,
   };
  ```

 * 最简答的插入, UpsertStage
   * UpsertStage::doWork 主逻辑，先调用 UpdateStage::doWork 函数，如果update成功，则直接退出，如果失败，则进入 插入模式.
   * insert 有两步, 1. 根据查询和更新条件，生成 需要插入的文档， 2. 调用 collection->insert 函数进行插入.
   * 插入成功后，根据配置决定是否需要返回插入文档，如果需要返回， stage 返回 advanced, 如不需要，返回 EOF.


   ```c++
/**
 * Execution stage for update requests with {upsert:true}. This is a specialized UpdateStage which,
 * in the event that no documents match the update request's query, generates and inserts a new
 * document into the collection. All logic related to the insertion phase is implemented by this
 * class.
 *
 * If the prior or newly-updated version of the document was requested to be returned, then ADVANCED
 * is returned after updating or inserting a document. Otherwise, NEED_TIME is returned after
 * updating a document if further updates are pending, and IS_EOF is returned if all updates have
 * been performed or if a document has been inserted.
 *
 * Callers of doWork() must be holding a write lock.
 */
   ```

 * update stage
   * update stage 使用 _updatedRecordIds 来记录是否有id使用过，这个在大量的update的时候，可能会有内存问题， 需要处理.
   * update stage 跟 update 语句并不是对应的，这里的 update stage 只是做了 更新操作， 查询类的操作放到了别的stage里去做了。
   * 在具体的 update 过程中， 先 savestate， 具体 update doc，然后再 restore state. 
   * update stage 过程中， 会有 writeunitofwork 的 commit操作， 那么就说， 这个 update 并不是原子的。
   * 所以如果想要 update 具有原子性，必须开启 mongodb的事务逻辑，这样， writeunitofwork 的commit才不会真正的落盘到表空间，才有rollback的逻辑. 
   
 * DocumentSource 算子
   * 这个应该是 pipeline 使用的算子，跟 stage 操作类似， 也是多个 pipeline 组成一个 tree 结构进行处理， 
   * Pipeline 的父接口为: Pipeline, pipeline 最重要的函数就是 getNext， 由他来实现不同 pipeline的逻辑

