---
title: mysql-二进制文件安装简易步骤
date: 2017-11-06 13:56:46
tags:
---



###自己在docker中安装mysql,因为要自定义端口号和相关内容,所以不能采用仓库包的方式进行mysql的安装.



1. 从mysql 官方网站现在mysql二进制包, 注意32位和64位即可.

2. 准备一份自定义的my.cnf这个mysql的配置文件, 这个文件我是从一个网页上生成的.

   <!-- more -->

   ```bash
   [client]
   port = 10000
   socket = /home/eharry/app/mysql/data/mysql.sock

   [mysql]
   prompt="\u@mysqldb \R:\m:\s [\d]> "
   no-auto-rehash

   [mysqld]
   user = mysql
   port = 10000
   basedir = /home/eharry/app/mysql/bin
   datadir = /home/eharry/app/mysql/data/data
   socket = /home/eharry/app/mysql/data/mysql.sock
   pid-file = mysqldb.pid
   character-set-server = utf8mb4
   skip_name_resolve = 1
   open_files_limit = 65535
   back_log = 1024
   max_connections = 8
   max_connect_errors = 1000000
   table_open_cache = 200
   table_definition_cache = 200
   table_open_cache_instances = 64
   thread_stack = 512K
   external-locking = FALSE
   max_allowed_packet = 32M
   sort_buffer_size = 4M
   join_buffer_size = 4M
   thread_cache_size = 12
   query_cache_size = 0
   query_cache_type = 0
   interactive_timeout = 600
   wait_timeout = 600
   tmp_table_size = 32M
   max_heap_table_size = 32M
   slow_query_log = 1
   slow_query_log_file = /home/eharry/app/mysql/data/data/slow.log
   log-error = /home/eharry/app/mysql/data/data/error.log
   long_query_time = 0.1
   log_queries_not_using_indexes =1
   log_throttle_queries_not_using_indexes = 60
   min_examined_row_limit = 100
   log_slow_admin_statements = 1
   log_slow_slave_statements = 1
   server-id = 10000
   log-bin = /home/eharry/app/mysql/data/data/mybinlog
   sync_binlog = 1
   binlog_cache_size = 4M
   max_binlog_cache_size = 2G
   max_binlog_size = 1G
   expire_logs_days = 7
   master_info_repository = TABLE
   relay_log_info_repository = TABLE
   gtid_mode = on
   enforce_gtid_consistency = 1
   log_slave_updates
   binlog_format = row
   relay_log_recovery = 1
   relay-log-purge = 1
   key_buffer_size = 32M
   read_buffer_size = 8M
   read_rnd_buffer_size = 4M
   bulk_insert_buffer_size = 64M
   myisam_sort_buffer_size = 128M
   myisam_max_sort_file_size = 10G
   myisam_repair_threads = 1
   lock_wait_timeout = 3600
   explicit_defaults_for_timestamp = 1
   innodb_thread_concurrency = 0
   innodb_sync_spin_loops = 100
   innodb_spin_wait_delay = 30

   transaction_isolation = REPEATABLE-READ
   #innodb_additional_mem_pool_size = 16M
   innodb_buffer_pool_size = 5734M
   innodb_buffer_pool_instances = 8
   innodb_buffer_pool_load_at_startup = 1
   innodb_buffer_pool_dump_at_shutdown = 1
   innodb_flush_log_at_trx_commit = 1
   innodb_log_buffer_size = 32M
   innodb_log_file_size = 2G
   innodb_log_files_in_group = 2
   innodb_max_undo_log_size = 4G

   # 根据您的服务器IOPS能力适当调整
   # 一般配普通SSD盘的话，可以调整到 10000 - 20000
   # 配置高端PCIe SSD卡的话，则可以调整的更高，比如 50000 - 80000
   innodb_io_capacity = 4000
   innodb_io_capacity_max = 8000
   innodb_flush_neighbors = 0
   innodb_write_io_threads = 8
   innodb_read_io_threads = 8
   innodb_purge_threads = 4
   innodb_page_cleaners = 4
   innodb_open_files = 65535
   innodb_max_dirty_pages_pct = 50
   #innodb_flush_method = O_DIRECT
   innodb_lru_scan_depth = 4000
   innodb_checksum_algorithm = crc32
   #innodb_file_format = Barracuda
   #innodb_file_format_max = Barracuda
   innodb_lock_wait_timeout = 10
   innodb_rollback_on_timeout = 1
   innodb_print_all_deadlocks = 1
   innodb_file_per_table = 1
   innodb_online_alter_log_max_size = 4G
   internal_tmp_disk_storage_engine = InnoDB
   innodb_stats_on_metadata = 0

   innodb_status_file = 1
   # 注意: 开启 innodb_status_output & innodb_status_output_locks 后, 可能会导致log-error文件增长较快
   innodb_status_output = 0
   innodb_status_output_locks = 0

   #performance_schema
   performance_schema = 1
   performance_schema_instrument = '%=on'

   #innodb monitor
   innodb_monitor_enable="module_innodb"
   innodb_monitor_enable="module_server"
   innodb_monitor_enable="module_dml"
   innodb_monitor_enable="module_ddl"
   innodb_monitor_enable="module_trx"
   innodb_monitor_enable="module_os"
   innodb_monitor_enable="module_purge"
   innodb_monitor_enable="module_log"
   innodb_monitor_enable="module_lock"
   innodb_monitor_enable="module_buffer"
   innodb_monitor_enable="module_index"
   innodb_monitor_enable="module_ibuf_system"
   innodb_monitor_enable="module_buffer_page"
   innodb_monitor_enable="module_adaptive_hash"

   [mysqldump]
   quick
   max_allowed_packet = 32M

   ```

3. 注意其中一些配置,用来隔离隔离不同的mysql使用的,例如

   ```bash
   [client]
   port = 10000
   socket = /home/eharry/app/mysql/data/mysql.sock
   [mysqld]
   port = 10000
   basedir = /home/eharry/app/mysql/bin
   datadir = /home/eharry/app/mysql/data/data
   socket = /home/eharry/app/mysql/data/mysql.sock
   slow_query_log_file = /home/eharry/app/mysql/data/data/slow.log
   log-error = /home/eharry/app/mysql/data/data/error.log
   log-bin = /home/eharry/app/mysql/data/data/mybinlog
   ```

4. 运行mysqld的初始化命令,初始化mysql数据

   ```bash
   mysqld --initialize --datadir=/home/eharry/app/mysql/data/data --user=eharry --basedir=/home/eharry/app/mysql/bin/
   ```

5. 命令输出如下, 注意下了文最后一行,这个初始化命令会生成一个临时密码,用于root@localhost的登录.

   ```bash
   2017-11-06T05:51:26.766491Z 0 [Warning] TIMESTAMP with implicit DEFAULT value is deprecated. Please use --explicit_defaults_for_timestamp server option (see documentation for more details).
   2017-11-06T05:51:26.778564Z 0 [Warning] Setting lower_case_table_names=2 because file system for /home/eharry/app/mysql/data/data/ is case insensitive
   2017-11-06T05:51:27.228353Z 0 [Warning] InnoDB: New log files created, LSN=45790
   2017-11-06T05:51:27.325004Z 0 [Warning] InnoDB: Creating foreign key constraint system tables.
   2017-11-06T05:51:27.336229Z 0 [Warning] No existing UUID has been found, so we assume that this is the first time that this server has been started. Generating a new UUID: 87a066c5-c2b6-11e7-b354-0
   242ac110002.
   2017-11-06T05:51:27.338506Z 0 [Warning] Gtid table is not ready to be used. Table 'mysql.gtid_executed' cannot be opened.
   2017-11-06T05:51:27.343051Z 1 [Note] A temporary password is generated for root@localhost: ,+M7uFHZk=Fv
   ```

   ​

6. (可选步骤) 如果第七步执行不成功,可先执行第六步.

   在直接运行mysqld启动脚本时,可能会出现如下错误:

   ```bash
   eharry@e8c1371ea79f:~$ cat app/mysql/data/data/error.log
   2017-11-06T23:12:09.614839Z 0 [Warning] option 'table_definition_cache': unsigned value 200 adjusted to 400
   2017-11-06T23:12:09.762923Z 0 [Note] --secure-file-priv is set to NULL. Operations related to importing and exporting data are disabled
   2017-11-06T23:12:09.762967Z 0 [Note] mysqld (mysqld 5.7.20-log) starting as process 713 ...
   2017-11-06T23:12:09.780477Z 0 [Warning] Setting lower_case_table_names=2 because file system for /home/eharry/app/mysql/data/data/ is case insensitive
   2017-11-06T23:12:09.785532Z 0 [Warning] One can only use the --user switch if running as root

   2017-11-06T23:12:09.793716Z 0 [Note] InnoDB: PUNCH HOLE support available
   2017-11-06T23:12:09.793977Z 0 [Note] InnoDB: Mutexes and rw_locks use GCC atomic builtins
   2017-11-06T23:12:09.794227Z 0 [Note] InnoDB: Uses event mutexes
   2017-11-06T23:12:09.794396Z 0 [Note] InnoDB: GCC builtin __sync_synchronize() is used for memory barrier
   2017-11-06T23:12:09.794573Z 0 [Note] InnoDB: Compressed tables use zlib 1.2.3
   2017-11-06T23:12:09.794730Z 0 [Note] InnoDB: Using Linux native AIO
   2017-11-06T23:12:09.795017Z 0 [Note] InnoDB: Number of pools: 1
   2017-11-06T23:12:09.795244Z 0 [Note] InnoDB: Using CPU crc32 instructions
   2017-11-06T23:12:09.796953Z 0 [Note] InnoDB: Initializing buffer pool, total size = 6G, instances = 8, chunk size = 128M
   2017-11-06T23:12:10.106476Z 0 [Note] InnoDB: Completed initialization of buffer pool
   2017-11-06T23:12:10.145947Z 0 [Note] InnoDB: If the mysqld execution user is authorized, page cleaner thread priority can be changed. See the man page of setpriority().
   2017-11-06T23:12:10.161893Z 0 [ERROR] InnoDB: The Auto-extending innodb_system data file './ibdata1' is of a different size 768 pages (rounded down to MB) than specified in the .cnf file: initial 65536 pages, max 0 (relevant if non-zero) pages!
   2017-11-06T23:12:10.162484Z 0 [ERROR] InnoDB: Plugin initialization aborted with error Generic error
   2017-11-06T23:12:10.777941Z 0 [ERROR] Plugin 'InnoDB' init function returned error.
   2017-11-06T23:12:10.778743Z 0 [ERROR] Plugin 'InnoDB' registration as a STORAGE ENGINE failed.
   2017-11-06T23:12:10.779166Z 0 [ERROR] Failed to initialize plugins.
   2017-11-06T23:12:10.779533Z 0 [ERROR] Aborting

   2017-11-06T23:12:10.780389Z 0 [Note] Binlog end
   2017-11-06T23:12:10.783590Z 0 [Note] mysqld: Shutdown complete
   ```

   这个错误表示, mysqld的配置文件和mysqld 初始化生成的数据间,存在着逻辑冲突, 

   注意,网上有人建议删掉data底下这些目录, 这种方法虽然能解决这个问题,让mysqld启动起来,但是这个方法可能造成系统中某些表的逻辑故障. 

   不建议使用这个方案:


   更应该使用的是删除my.cnf中相关配置文件.
    innodb_data_file_path = ibdata1:1G:autoextend
    注意删除配置文件中,相关innodb_data_file_path的配置.


8. 执行mysqld启动命令, 指定步骤2得到的mysql配置文件

   ```bash
   mysqld --defaults-file=/home/eharry/app/mysql/data/conf/my.cnf &
   ```

   通过ps命令,可以看到mysqld已经运行起来了

   ```bash
   eharry@e8c1371ea79f:~$ ps -ef | grep mysqld
   eharry     745   537  6 23:19 pts/2    00:00:03 mysqld --defaults-file=/home/eharry/app/mysql/data/conf/my.cnf
   eharry     787   628  0 23:20 pts/3    00:00:00 grep mysqld
   ```

   ​

9. 根据初始化生成的临时密码,连接mysql数据库

   注意: 需要手动指定mysql.sock所在路径,如下命令所示

   ```bash
   eharry@e8c1371ea79f:~$ mysql -u root -p -S /home/eharry/app/mysql/data/mysql.sock
   Enter password:
   Welcome to the MySQL monitor.  Commands end with ; or \g.
   Your MySQL connection id is 3
   Server version: 5.7.20-log

   Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

   Oracle is a registered trademark of Oracle Corporation and/or its
   affiliates. Other names may be trademarks of their respective
   owners.

   Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

   mysql>
   ```

   ​