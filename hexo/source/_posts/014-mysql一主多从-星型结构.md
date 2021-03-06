---
title: mysql一主多从-星型结构
date: 2017-11-13 13:16:31
tags: mysql
---



前面.说了最简单的mysql 主备方式的配置, 那就是简单的一主一从的配置.

今天要说一下,一主多从的配置方式.

一主多从又分为好几种配置, 根据拓扑的不同, 简单的分为 星型结构和链式结构.

* 星型结构
  * 配置主机,按照前面的方式
  * 配置第一台备机,按照前面的方式配置.
  * 配置第二胎备机,还按照前面的方式配置.



这里完全跟前面的配置一样, 可以看出,第一台备机和第二台备机的配置,完全没有差异.

他们之间也不会互相影响.



从主机上可以看出,复制关系仍然正常建立

```bash
mysql> SHOW PROCESSLIST;
+----+------+------------------+------+-------------+-------+---------------------------------------------------------------+------------------+
| Id | User | Host             | db   | Command     | Time  | State                                                         | Info             |
+----+------+------------------+------+-------------+-------+---------------------------------------------------------------+------------------+
|  4 | repl | 172.17.0.3:52312 | NULL | Binlog Dump | 52670 | Master has sent all binlog to slave; waiting for more updates | NULL             |
|  9 | repl | 172.17.0.4:44848 | NULL | Binlog Dump |   394 | Master has sent all binlog to slave; waiting for more updates | NULL             |
| 10 | root | localhost        | NULL | Query       |     0 | starting                                                      | SHOW PROCESSLIST |
+----+------+------------------+------+-------------+-------+---------------------------------------------------------------+------------------+
3 rows in set (0.00 sec)
```

**SHOW SLAVE HOSTS**

```bash
mysql> SHOW SLAVE HOSTS;
+-----------+------+-------+-----------+--------------------------------------+
| Server_id | Host | Port  | Master_id | Slave_UUID                           |
+-----------+------+-------+-----------+--------------------------------------+
|         3 |      | 10000 |         1 | 1841a4b2-c834-11e7-99ee-0242ac110004 |
|         2 |      | 10000 |         1 | 4d8df011-c7a4-11e7-bf90-0242ac110003 |
+-----------+------+-------+-----------+--------------------------------------+
2 rows in set (0.00 sec)
```

