---
title: 050-wt-truncate
date: 2021-09-23 07:15:52
tags:
---



### 简单浏览一下 wt session truncate 命令的实现

<!--more-->

```txt
__session_truncate function ->  __wt_session_range_truncate->  __wt_schema_range_truncate -> __wt_table_range_truncate -> 然后分别调用，删除索引和数据， 
WT_ERR(__apply_idx(stop, offsetof(WT_CURSOR, remove), false)); 删除索引
__wt_range_truncate 删除数据

```

* 从代码看，就是硬删，没有使用额外的高级功能。
