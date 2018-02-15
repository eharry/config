---
title: mysql-new-install-change-password
date: 2017-11-10 22:42:57
tags:
---



mysql 新安装成功后, 在初始化脚本中,他们会给你一个登陆localhost的root密码.

但这个密码只能用于登陆, 

除了登陆的其他操作,mysql都会提示你做密码修改.



如下所示:

```bash
mysql> show databases;
ERROR 1820 (HY000): You must reset your password using ALTER USER statement before executing this statement.
```



mysql 修改密码, 详情参见文档: https://dev.mysql.com/doc/refman/5.7/en/resetting-permissions.html

下面介绍一种我自己使用的方式, 这也是官方文档所推荐的方式.

```bash
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
Query OK, 0 rows affected (0.01 sec)
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0.02 sec)
```

可以看出,当密码修改后, root用户已经可以正常的操作mysql数据库了.