---
title: mysql主备复制关系建立
date: 2017-11-11 20:22:52
tags:
---

* mysql主备关系建立
  * 前提
    * 首先需要一个mysql主机环境

    * 其次需要一个mysql备机环境

    * 保证mysql主机环境和备机环境的网络相同

    * 保证两个环境的serverid不一致, 要不然无法建立主备关系

      * ```bash
        mysql1 环境
        mysql> show variables like 'server_id';
        +---------------+-------+
        | Variable_name | Value |
        +---------------+-------+
        | server_id     | 1     |
        +---------------+-------+
        1 row in set (0.00 sec)
        ```

      * ```bash
        mysql2环境
        mysql> show variables like 'server_id';
        +---------------+-------+
        | Variable_name | Value |
        +---------------+-------+
        | server_id     | 2     |
        +---------------+-------+
        1 row in set (0.01 sec)
        ```

<!-- more -->

  * 操作步骤

    * 建立一个账户用于数据同步

      * 查看当前数据库有哪些账户

        * ```bash
          mysql> desc mysql.user;
          +------------------------+-----------------------------------+------+-----+-----------------------+-------+
          | Field                  | Type                              | Null | Key | Default               | Extra |
          +------------------------+-----------------------------------+------+-----+-----------------------+-------+
          | Host                   | char(60)                          | NO   | PRI |                       |       |
          | User                   | char(32)                          | NO   | PRI |                       |       |
          | Select_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Insert_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Update_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Delete_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Drop_priv              | enum('N','Y')                     | NO   |     | N                     |       |
          | Reload_priv            | enum('N','Y')                     | NO   |     | N                     |       |
          | Shutdown_priv          | enum('N','Y')                     | NO   |     | N                     |       |
          | Process_priv           | enum('N','Y')                     | NO   |     | N                     |       |
          | File_priv              | enum('N','Y')                     | NO   |     | N                     |       |
          | Grant_priv             | enum('N','Y')                     | NO   |     | N                     |       |
          | References_priv        | enum('N','Y')                     | NO   |     | N                     |       |
          | Index_priv             | enum('N','Y')                     | NO   |     | N                     |       |
          | Alter_priv             | enum('N','Y')                     | NO   |     | N                     |       |
          | Show_db_priv           | enum('N','Y')                     | NO   |     | N                     |       |
          | Super_priv             | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_tmp_table_priv  | enum('N','Y')                     | NO   |     | N                     |       |
          | Lock_tables_priv       | enum('N','Y')                     | NO   |     | N                     |       |
          | Execute_priv           | enum('N','Y')                     | NO   |     | N                     |       |
          | Repl_slave_priv        | enum('N','Y')                     | NO   |     | N                     |       |
          | Repl_client_priv       | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_view_priv       | enum('N','Y')                     | NO   |     | N                     |       |
          | Show_view_priv         | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_routine_priv    | enum('N','Y')                     | NO   |     | N                     |       |
          | Alter_routine_priv     | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_user_priv       | enum('N','Y')                     | NO   |     | N                     |       |
          | Event_priv             | enum('N','Y')                     | NO   |     | N                     |       |
          | Trigger_priv           | enum('N','Y')                     | NO   |     | N                     |       |
          | Create_tablespace_priv | enum('N','Y')                     | NO   |     | N                     |       |
          | ssl_type               | enum('','ANY','X509','SPECIFIED') | NO   |     |                       |       |
          | ssl_cipher             | blob                              | NO   |     | NULL                  |       |
          | x509_issuer            | blob                              | NO   |     | NULL                  |       |
          | x509_subject           | blob                              | NO   |     | NULL                  |       |
          | max_questions          | int(11) unsigned                  | NO   |     | 0                     |       |
          | max_updates            | int(11) unsigned                  | NO   |     | 0                     |       |
          | max_connections        | int(11) unsigned                  | NO   |     | 0                     |       |
          | max_user_connections   | int(11) unsigned                  | NO   |     | 0                     |       |
          | plugin                 | char(64)                          | NO   |     | mysql_native_password |       |
          | authentication_string  | text                              | YES  |     | NULL                  |       |
          | password_expired       | enum('N','Y')                     | NO   |     | N                     |       |
          | password_last_changed  | timestamp                         | YES  |     | NULL                  |       |
          | password_lifetime      | smallint(5) unsigned              | YES  |     | NULL                  |       |
          | account_locked         | enum('N','Y')                     | NO   |     | N                     |       |
          +------------------------+-----------------------------------+------+-----+-----------------------+-------+
          45 rows in set (0.00 sec)
          ```

        * 使用select 查询mysql.user表, 查询系统中有几个用户

        * ```bash
          mysql> select Host,User from mysql.user;
          +-----------+---------------+
          | Host      | User          |
          +-----------+---------------+
          | localhost | mysql.session |
          | localhost | mysql.sys     |
          | localhost | root          |
          +-----------+---------------+
          3 rows in set (0.00 sec)
          ```

        * 创建用户,使用create user命令, create user语法如下:

        * ```bash
          CREATE USER [IF NOT EXISTS]
              user [auth_option] [, user [auth_option]] ...
              [REQUIRE {NONE | tls_option [[AND] tls_option] ...}]
              [WITH resource_option [resource_option] ...]
              [password_option | lock_option] ...
          ```

        * ```bash
          mysql> CREATE USER 'repl'@'%' IDENTIFIED BY 'repl_password';
          Query OK, 0 rows affected (0.05 sec)

          mysql> select host,user from mysql.user;
          +-----------+---------------+
          | host      | user          |
          +-----------+---------------+
          | %         | repl          |
          | localhost | mysql.session |
          | localhost | mysql.sys     |
          | localhost | root          |
          +-----------+---------------+
          4 rows in set (0.00 sec)
          ```

      * 下来赋予repl这个账号复制权限
        * ```bash
          mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
          Query OK, 0 rows affected (0.00 sec)

          ```

        * 查看权限是否设置成功

        * ```bash
          mysql> select * from mysql.user where user = 'repl' \G;
          *************************** 1. row ***************************
                            Host: %
                            User: repl
                     Select_priv: N
                     Insert_priv: N
                     Update_priv: N
                     Delete_priv: N
                     Create_priv: N
                       Drop_priv: N
                     Reload_priv: N
                   Shutdown_priv: N
                    Process_priv: N
                       File_priv: N
                      Grant_priv: N
                 References_priv: N
                      Index_priv: N
                      Alter_priv: N
                    Show_db_priv: N
                      Super_priv: N
           Create_tmp_table_priv: N
                Lock_tables_priv: N
                    Execute_priv: N
                 Repl_slave_priv: Y
                            ^^^^^^^^^^^^^^^^可以看出,已经设置好了
                Repl_client_priv: N
                Create_view_priv: N
                  Show_view_priv: N
             Create_routine_priv: N
              Alter_routine_priv: N
                Create_user_priv: N
                      Event_priv: N
                    Trigger_priv: N
          Create_tablespace_priv: N
                        ssl_type:
                      ssl_cipher:
                     x509_issuer:
                    x509_subject:
                   max_questions: 0
                     max_updates: 0
                 max_connections: 0
            max_user_connections: 0
                          plugin: mysql_native_password
           authentication_string: *E10F09E41DEE2943D20B11E2A6A03A81E41F2D89
                password_expired: N
           password_last_changed: 2017-11-12 11:28:47
               password_lifetime: NULL
                  account_locked: N
          1 row in set (0.00 sec)

          ERROR:
          No query specified

          ```

        * 注意, 在一些别的博客上, 我们经常看到类似地下语句:

        * ```bash
          mysql>GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'root@'%' IDENTIFIED BY 'root';
          ```

        * 上面的语句,将创建用户和给用户指定权限两个功能合二为一, 这个是利用了grant的一个特性,但这个操作是官方不建议的操作.

        * ```txt
          Note
          If an account named in a GRANT statement does not already exist, GRANT may create it under the conditions described later in the discussion of the NO_AUTO_CREATE_USER SQL mode. It is also possible to use GRANT to specify nonprivilege account characteristics such as whether it uses secure connections and limits on access to server resources.

          However, use of GRANT to create accounts or define nonprivilege characteristics is deprecated as of MySQL 5.7.6. Instead, perform these tasks using CREATE USER or ALTER USER.
          ```

        * 在备机上做同样的操作,然后保证两个mysql,都已经repl账号,并且设置了相应的密码

      * 在备机设置master地址
        * CHANGE MASTER TO Syntax

          * ```bash
            CHANGE MASTER TO option [, option] ... [ channel_option ]

            option:
                MASTER_BIND = 'interface_name'
              | MASTER_HOST = 'host_name'
              | MASTER_USER = 'user_name'
              | MASTER_PASSWORD = 'password'
              | MASTER_PORT = port_num
              | MASTER_CONNECT_RETRY = interval
              | MASTER_RETRY_COUNT = count
              | MASTER_DELAY = interval
              | MASTER_HEARTBEAT_PERIOD = interval
              | MASTER_LOG_FILE = 'master_log_name'
              | MASTER_LOG_POS = master_log_pos
              | MASTER_AUTO_POSITION = {0|1}
              | RELAY_LOG_FILE = 'relay_log_name'
              | RELAY_LOG_POS = relay_log_pos
              | MASTER_SSL = {0|1}
              | MASTER_SSL_CA = 'ca_file_name'
              | MASTER_SSL_CAPATH = 'ca_directory_name'
              | MASTER_SSL_CERT = 'cert_file_name'
              | MASTER_SSL_CRL = 'crl_file_name'
              | MASTER_SSL_CRLPATH = 'crl_directory_name'
              | MASTER_SSL_KEY = 'key_file_name'
              | MASTER_SSL_CIPHER = 'cipher_list'
              | MASTER_SSL_VERIFY_SERVER_CERT = {0|1}
              | MASTER_TLS_VERSION = 'protocol_list'
              | IGNORE_SERVER_IDS = (server_id_list)

            channel_option:
                FOR CHANNEL channel

            server_id_list:
                [server_id [, server_id] ... ]
            ```

          * 检查主机的当前的bin log和position

          * ```bash
            mysql> show master status \G;
            *************************** 1. row ***************************
                         File: mybinlog.000001
                     Position: 839
                 Binlog_Do_DB:
             Binlog_Ignore_DB:
            Executed_Gtid_Set: ed0cc966-c7b9-11e7-bc17-0242ac110002:1-3
            1 row in set (0.00 sec)
            ```

          * ​

          * 在备机运行change master to

          * ```bash
            mysql> CHANGE MASTER TO
                ->   MASTER_HOST='172.17.0.2',
                ->   MASTER_USER='repl',
                ->   MASTER_PASSWORD='repl_password',
                ->   MASTER_PORT=10000,
                ->   MASTER_LOG_FILE='mybinlog.000001',
                ->   MASTER_LOG_POS=839,
                ->   MASTER_CONNECT_RETRY=3;
            Query OK, 0 rows affected, 2 warnings (0.04 sec)
            ```

          * 在备机运行show slave status

          * ```bash
            mysql> show slave status \G;
            *************************** 1. row ***************************
                           Slave_IO_State:
                              Master_Host: 172.17.0.2
                              Master_User: repl
                              Master_Port: 10000
                            Connect_Retry: 3
                          Master_Log_File: mybinlog.000001
                      Read_Master_Log_Pos: 839
                           Relay_Log_File: 2d7143dab7a4-relay-bin.000001
                            Relay_Log_Pos: 4
                    Relay_Master_Log_File: mybinlog.000001
                         Slave_IO_Running: No
                        Slave_SQL_Running: No
                          Replicate_Do_DB:
                      Replicate_Ignore_DB:
                       Replicate_Do_Table:
                   Replicate_Ignore_Table:
                  Replicate_Wild_Do_Table:
              Replicate_Wild_Ignore_Table:
                               Last_Errno: 0
                               Last_Error:
                             Skip_Counter: 0
                      Exec_Master_Log_Pos: 839
                          Relay_Log_Space: 154
                          Until_Condition: None
                           Until_Log_File:
                            Until_Log_Pos: 0
                       Master_SSL_Allowed: No
                       Master_SSL_CA_File:
                       Master_SSL_CA_Path:
                          Master_SSL_Cert:
                        Master_SSL_Cipher:
                           Master_SSL_Key:
                    Seconds_Behind_Master: NULL
            Master_SSL_Verify_Server_Cert: No
                            Last_IO_Errno: 0
                            Last_IO_Error:
                           Last_SQL_Errno: 0
                           Last_SQL_Error:
              Replicate_Ignore_Server_Ids:
                         Master_Server_Id: 0
                              Master_UUID:
                         Master_Info_File: mysql.slave_master_info
                                SQL_Delay: 0
                      SQL_Remaining_Delay: NULL
                  Slave_SQL_Running_State:
                       Master_Retry_Count: 86400
                              Master_Bind:
                  Last_IO_Error_Timestamp:
                 Last_SQL_Error_Timestamp:
                           Master_SSL_Crl:
                       Master_SSL_Crlpath:
                       Retrieved_Gtid_Set:
                        Executed_Gtid_Set: 4d8df011-c7a4-11e7-bf90-0242ac110003:1-3
                            Auto_Position: 0
                     Replicate_Rewrite_DB:
                             Channel_Name:
                       Master_TLS_Version:
            1 row in set (0.00 sec)
            ```

          * 然后运行start slave后,再次查看slave 状态

          * ```bash
            mysql> start slave
                -> ;
            Query OK, 0 rows affected (0.02 sec)
            ```

          * ```bash
            mysql> show slave status \G;
            *************************** 1. row ***************************
                           Slave_IO_State: Waiting for master to send event
                              Master_Host: 172.17.0.2
                              Master_User: repl
                              Master_Port: 10000
                            Connect_Retry: 3
                          Master_Log_File: mybinlog.000001
                      Read_Master_Log_Pos: 839
                           Relay_Log_File: 2d7143dab7a4-relay-bin.000002
                            Relay_Log_Pos: 319
                    Relay_Master_Log_File: mybinlog.000001
                         Slave_IO_Running: Yes
                        Slave_SQL_Running: Yes
                          Replicate_Do_DB:
                      Replicate_Ignore_DB:
                       Replicate_Do_Table:
                   Replicate_Ignore_Table:
                  Replicate_Wild_Do_Table:
              Replicate_Wild_Ignore_Table:
                               Last_Errno: 0
                               Last_Error:
                             Skip_Counter: 0
                      Exec_Master_Log_Pos: 839
                          Relay_Log_Space: 533
                          Until_Condition: None
                           Until_Log_File:
                            Until_Log_Pos: 0
                       Master_SSL_Allowed: No
                       Master_SSL_CA_File:
                       Master_SSL_CA_Path:
                          Master_SSL_Cert:
                        Master_SSL_Cipher:
                           Master_SSL_Key:
                    Seconds_Behind_Master: 0
            Master_SSL_Verify_Server_Cert: No
                            Last_IO_Errno: 0
                            Last_IO_Error:
                           Last_SQL_Errno: 0
                           Last_SQL_Error:
              Replicate_Ignore_Server_Ids:
                         Master_Server_Id: 1
                              Master_UUID: ed0cc966-c7b9-11e7-bc17-0242ac110002
                         Master_Info_File: mysql.slave_master_info
                                SQL_Delay: 0
                      SQL_Remaining_Delay: NULL
                  Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
                       Master_Retry_Count: 86400
                              Master_Bind:
                  Last_IO_Error_Timestamp:
                 Last_SQL_Error_Timestamp:
                           Master_SSL_Crl:
                       Master_SSL_Crlpath:
                       Retrieved_Gtid_Set:
                        Executed_Gtid_Set: 4d8df011-c7a4-11e7-bf90-0242ac110003:1-3
                            Auto_Position: 0
                     Replicate_Rewrite_DB:
                             Channel_Name:
                       Master_TLS_Version:
            1 row in set (0.00 sec)
            ```

      * 验证主备是否配置成功
        * 在主机建立一个test1数据库

        * ```bash
          mysql> create database test1;
          Query OK, 1 row affected (0.01 sec)

          mysql> show databases;
          +--------------------+
          | Database           |
          +--------------------+
          | information_schema |
          | mysql              |
          | performance_schema |
          | sys                |
          | test1              |
          +--------------------+
          5 rows in set (0.03 sec)
          ```

        * 在备机查看数据库信息

        * ```bash
          mysql> show databases;
          +--------------------+
          | Database           |
          +--------------------+
          | information_schema |
          | mysql              |
          | performance_schema |
          | sys                |
          | test1              |
          +--------------------+
          5 rows in set (0.03 sec)
          ```

    * 可以看出主备关系已经成功建立, 当主机出现故障的时候,备机可以直接使用.