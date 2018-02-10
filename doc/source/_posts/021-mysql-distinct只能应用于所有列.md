---
title: 021-mysql-distinct只能应用于所有列
date: 2017-12-02 21:45:02
tags: mysql
---



mysql的distinct描述,是用来表示输出只能显示不同的值,相同的值被略去



* distinct 究竟是作用于一列,还是多列
* distinct 与 limit合用时,当有前面的数据重合时, limit会不会补位呢?

<!--more-->



### distinct 究竟是作用于一列,还是多列

如下所示, 数据库有4行数据,其中对于a1列来说, 只有两个值, 分别是1和3

```bash
mysql> select * from b;
+------+------+
| a1   | a2   |
+------+------+
|    1 |    2 |
|    3 |    4 |
|    1 |    3 |
|    1 |    3 |
+------+------+
4 rows in set (0.00 sec)
```

一般情况下,我们选择a1列的输出是用: select a1 from b;

```bash
mysql> select a1 from b;
+------+
| a1   |
+------+
|    1 |
|    3 |
|    1 |
|    1 |
+------+
4 rows in set (0.00 sec)
```

如果为了得到不一样值,则使用sql : select distinct a1 from b;

```bash
mysql> select distinct a1 from b;
+------+
| a1   |
+------+
|    1 |
|    3 |
+------+
2 rows in set (0.00 sec)
```

 这时候,如果我们的输出列又加上一列a2值, distinct会是什么行为呢? 是修饰a1列显示不同,还是a1,a2列显示的不同值呢?

```bash
mysql> select distinct a1,a2 from b;
+------+------+
| a1   | a2   |
+------+------+
|    1 |    2 |
|    3 |    4 |
|    1 |    3 |
+------+------+
3 rows in set (0.00 sec)
```

由上面实验,可以看出,他修饰的是a1和a2两个列的显示行为



```bash
The ALL and DISTINCT modifiers specify whether duplicate rows should be returned. ALL (the default) specifies that all matching rows should be returned, including duplicates. DISTINCT specifies removal of duplicate rows from the result set. It is an error to specify both modifiers. DISTINCTROW is a synonym for DISTINCT.
```



### distinct 与 limit合用时,当有前面的数据重合时, limit会不会补位呢?

1. 全量数据为

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
   5 rows in set (0.00 sec)
   ```

2. 只有distinct的数据, 可以看出原始数据的第四行被忽略了显示

   ```bash
   mysql> select distinct a1,a2 from b;
   +------+------+
   | a1   | a2   |
   +------+------+
   |    1 |    2 |
   |    3 |    4 |
   |    1 |    3 |
   |    1 |    4 |
   +------+------+
   4 rows in set (0.00 sec)
   ```

3. 如果加上limit 为4,我们再看一下效果

   ```bash
   mysql> select distinct a1,a2 from b limit 4;
   +------+------+
   | a1   | a2   |
   +------+------+
   |    1 |    2 |
   |    3 |    4 |
   |    1 |    3 |
   |    1 |    4 |
   +------+------+
   4 rows in set (0.00 sec)
   ```

   由这个结果可以看出, limit生效是在distinct之后,.

4. 补充一个纯limit的运行结果

   ```bash
   mysql> select a1,a2 from b limit 4;
   +------+------+
   | a1   | a2   |
   +------+------+
   |    1 |    2 |
   |    3 |    4 |
   |    1 |    3 |
   |    1 |    3 |
   +------+------+
   4 rows in set (0.00 sec)
   ```

   ​

