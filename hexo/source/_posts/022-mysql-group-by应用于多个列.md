---
title: 022-mysql-group-by应用于多个列
date: 2017-12-06 23:59:08
tags:
---



group by做位分组函数, 简单的用法可以分组给定的列

如下所示, 系统中所有数据为

```bash
mysql> select * from b;
+------+------+
| a1   | a2   |
+------+------+
|    1 |    2 |
|    3 |    4 |
|    1 |    3 |
|    1 |    3 |
|    1 |    4 |
+------+------+
5 rows in set (0.01 sec)
```

如果对a1进行group by操作,

```bash
mysql> select a1 from b group by a1;
+------+
| a1   |
+------+
|    1 |
|    3 |
+------+
2 rows in set (0.00 sec)
```

可以看出, 只是将a1,两行不同的值被group起来了



接下来,我们试试,看能否指定查询列和group by不同列

```bash
mysql> select a1 from b group by a2;
ERROR 1055 (42000): Expression #1 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'test1.b.a1' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
```

可以看出,mysql不允许这种方式使用.



但是如果使用了聚集函数,那么还是允许select列和group by列不相同的

```bash
mysql> select count(a2) from b group by a1;
+-----------+
| count(a2) |
+-----------+
|         4 |
|         1 |
+-----------+
2 rows in set (0.00 sec)
```

可以看出,group by仍然按照a1进行分类.



那么group by是否可以使用到多个列中呢?

```bash
mysql> select a1,a2 from b group by a1,a2;
+------+------+
| a1   | a2   |
+------+------+
|    1 |    2 |
|    1 |    3 |
|    1 |    4 |
|    3 |    4 |
+------+------+
4 rows in set (0.00 sec)
```



可以看出,按照a1和a2的联合方式进行了group操作.



* select *  是否可以用在 group中

  ```bash
  mysql> select * from b group by a1,a2;
  +------+------+
  | a1   | a2   |
  +------+------+
  |    1 |    2 |
  |    1 |    3 |
  |    1 |    4 |
  |    3 |    4 |
  +------+------+
  4 rows in set (0.00 sec)
  ```

  对于 group by全部列来说,是允许的.

  对于group by部分列来说, 是不允许的

  ```bash
  mysql> select * from b group by a1;
  ERROR 1055 (42000): Expression #2 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'test1.b.a2' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
  ```

  ​

* group by后面是否可以加*

  ```bash
  mysql> select * from b group by *;
  ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near '*' at line 1
  ```

  答案, 不行

  ​