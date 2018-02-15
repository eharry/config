---
title: 001-mysql半同步模式建立
date: 2017-11-15 12:46:51
tags:
---



搭建mysql半同步的模式

* 前提
  * 已经搭建了mysql主备异步模式

* 步骤

  * 主节点安装master.so

    ```bash
    install plugin rpl_semi_sync_master soname 'semisync_master.so';
    ```

    ​

  * 备节点安装slave.so

    ```
    install plugin rpl_semi_sync_slave soname 'semisync_slave.so';
    ```

  * 在主节点上运行查看系统配置命令

    ```bash
    mysql> show variables like 'rpl%';
    +-------------------------------------------+------------+
    | Variable_name                             | Value      |
    +-------------------------------------------+------------+
    | rpl_semi_sync_master_enabled              | OFF        |
    | rpl_semi_sync_master_timeout              | 10000      |
    | rpl_semi_sync_master_trace_level          | 32         |
    | rpl_semi_sync_master_wait_for_slave_count | 1          |
    | rpl_semi_sync_master_wait_no_slave        | ON         |
    | rpl_semi_sync_master_wait_point           | AFTER_SYNC |
    | rpl_stop_slave_timeout                    | 31536000   |
    +-------------------------------------------+------------+
    7 rows in set (0.01 sec)
    ```

    可以看到master默认并没有开启半同步模式, 需要手动开启, 运行下面命令

    ```bash
    mysql> set global rpl_semi_sync_master_enabled=1;
    Query OK, 0 rows affected (0.00 sec)

    mysql> show variables like 'rpl%';
    +-------------------------------------------+------------+
    | Variable_name                             | Value      |
    +-------------------------------------------+------------+
    | rpl_semi_sync_master_enabled              | ON         |
    | rpl_semi_sync_master_timeout              | 10000      |
    | rpl_semi_sync_master_trace_level          | 32         |
    | rpl_semi_sync_master_wait_for_slave_count | 1          |
    | rpl_semi_sync_master_wait_no_slave        | ON         |
    | rpl_semi_sync_master_wait_point           | AFTER_SYNC |
    | rpl_stop_slave_timeout                    | 31536000   |
    +-------------------------------------------+------------+
    7 rows in set (0.01 sec)
    ```

  * 在备节点运行set命令,修改半同步配置

    ```bash
    mysql> show variables like 'rpl%';
    +---------------------------------+----------+
    | Variable_name                   | Value    |
    +---------------------------------+----------+
    | rpl_semi_sync_slave_enabled     | OFF      |
    | rpl_semi_sync_slave_trace_level | 32       |
    | rpl_stop_slave_timeout          | 31536000 |
    +---------------------------------+----------+
    3 rows in set (0.00 sec)

    mysql> set global rpl_semi_sync_slave_enabled=1;
    Query OK, 0 rows affected (0.00 sec)

    mysql> show variables like 'rpl%';
    +---------------------------------+----------+
    | Variable_name                   | Value    |
    +---------------------------------+----------+
    | rpl_semi_sync_slave_enabled     | ON       |
    | rpl_semi_sync_slave_trace_level | 32       |
    | rpl_stop_slave_timeout          | 31536000 |
    +---------------------------------+----------+
    3 rows in set (0.00 sec)
    ```

  * 重启io线程
    ```bash
    mysql> stop slave io_thread;
    Query OK, 0 rows affected (0.01 sec)

    mysql> start slave io_thread;
    Query OK, 0 rows affected (0.00 sec)
    ```

* 检查半同步是否升值成功
  * 在主节点运行show命令

    ```bash
    mysql> show global status like '%semi%';
    +--------------------------------------------+-------+
    | Variable_name                              | Value |
    +--------------------------------------------+-------+
    | Rpl_semi_sync_master_clients               | 1     |
    | Rpl_semi_sync_master_net_avg_wait_time     | 0     |
    | Rpl_semi_sync_master_net_wait_time         | 0     |
    | Rpl_semi_sync_master_net_waits             | 0     |
    | Rpl_semi_sync_master_no_times              | 1     |
    | Rpl_semi_sync_master_no_tx                 | 0     |
    | Rpl_semi_sync_master_status                | ON    |
    | Rpl_semi_sync_master_timefunc_failures     | 0     |
    | Rpl_semi_sync_master_tx_avg_wait_time      | 0     |
    | Rpl_semi_sync_master_tx_wait_time          | 0     |
    | Rpl_semi_sync_master_tx_waits              | 0     |
    | Rpl_semi_sync_master_wait_pos_backtraverse | 0     |
    | Rpl_semi_sync_master_wait_sessions         | 0     |
    | Rpl_semi_sync_master_yes_tx                | 0     |
    +--------------------------------------------+-------+
    14 rows in set (0.00 sec)
    ```

  * 在备节点运行show命令

    ```bash
    mysql> show global status like '%semi%';
    +----------------------------+-------+
    | Variable_name              | Value |
    +----------------------------+-------+
    | Rpl_semi_sync_slave_status | ON    |
    +----------------------------+-------+
    1 row in set (0.00 sec)
    ```

* 在主节点test1数据库创建新的表t, 查看半同步的状态

  * 主节点

    ```bash
    mysql> show global status like '%semi%';
    +--------------------------------------------+-------+
    | Variable_name                              | Value |
    +--------------------------------------------+-------+
    | Rpl_semi_sync_master_clients               | 1     |
    | Rpl_semi_sync_master_net_avg_wait_time     | 0     |
    | Rpl_semi_sync_master_net_wait_time         | 0     |
    | Rpl_semi_sync_master_net_waits             | 1     |
    | Rpl_semi_sync_master_no_times              | 1     |
    | Rpl_semi_sync_master_no_tx                 | 0     |
    | Rpl_semi_sync_master_status                | ON    |
    | Rpl_semi_sync_master_timefunc_failures     | 0     |
    | Rpl_semi_sync_master_tx_avg_wait_time      | 1095  |
    | Rpl_semi_sync_master_tx_wait_time          | 1095  |
    | Rpl_semi_sync_master_tx_waits              | 1     |
    | Rpl_semi_sync_master_wait_pos_backtraverse | 0     |
    | Rpl_semi_sync_master_wait_sessions         | 0     |
    | Rpl_semi_sync_master_yes_tx                | 1     |
    +--------------------------------------------+-------+
    14 rows in set (0.00 sec)
    ```

    ​

