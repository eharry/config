---
title: 024-mysql-join-初步试用
date: 2017-12-07 22:36:39
tags:
---

数据库中存在两个表,k1和k2:

```bash
mysql> select * from k1;
+----+--------+
| id | name   |
+----+--------+
|  1 | name_a |
|  2 | name_b |
+----+--------+
2 rows in set (0.01 sec)

mysql> select * from k2;
+----+---------+
| id | value   |
+----+---------+
|  1 | value_a |
|  2 | value_b |
+----+---------+
2 rows in set (0.00 sec)
```



利用where进行join操作

```bash
mysql> select k1.id,k1.name,k2.value from k1,k2 where k1.id=k2.id;
+----+--------+---------+
| id | name   | value   |
+----+--------+---------+
|  1 | name_a | value_a |
|  2 | name_b | value_b |
+----+--------+---------+
2 rows in set (0.00 sec)
```

利用inner join进行操作

```bash
mysql> select k1.id,k1.name,k2.value from k1 inner join k2 on k1.id=k2.id;
+----+--------+---------+
| id | name   | value   |
+----+--------+---------+
|  1 | name_a | value_a |
|  2 | name_b | value_b |
+----+--------+---------+
2 rows in set (0.00 sec)
```



如果where 没有连接条件的情况下, 同时select 两张表会发生什么呢?

```bash
mysql> select * from k1,k2;
+----+--------+----+---------+
| id | name   | id | value   |
+----+--------+----+---------+
|  1 | name_a |  1 | value_a |
|  2 | name_b |  1 | value_a |
|  1 | name_a |  2 | value_b |
|  2 | name_b |  2 | value_b |
+----+--------+----+---------+
4 rows in set (0.00 sec)
```

可以看出,上面的语句,将k1里面的所有行和k2表里面的所有行进行了全排列的输出.



如果join操作后面不跟on的连接限制,也会是同样的效果

```bash
mysql> select k1.id,k1.name,k2.value from k1 inner join k2;
+----+--------+---------+
| id | name   | value   |
+----+--------+---------+
|  1 | name_a | value_a |
|  2 | name_b | value_a |
|  1 | name_a | value_b |
|  2 | name_b | value_b |
+----+--------+---------+
4 rows in set (0.00 sec)
```





