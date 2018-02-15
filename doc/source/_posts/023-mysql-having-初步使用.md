---
title: 023-mysql-having-初步使用
date: 2017-12-07 13:34:22
tags:
---

* having 配合 group by 一起使用

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

  mysql> select a1,a2 from b group by a1,a2 having a1!=3;
  +------+------+
  | a1   | a2   |
  +------+------+
  |    1 |    2 |
  |    1 |    3 |
  |    1 |    4 |
  +------+------+
  3 rows in set (0.01 sec)
  ```

  可以看出, having 可以直接过滤掉一个分组结果



* having和where的功能很类似,where应用于行的搜索, having应用于分组的搜索.

