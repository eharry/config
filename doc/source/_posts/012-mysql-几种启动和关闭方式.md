---
title: mysql-几种启动和关闭方式
date: 2017-11-11 13:29:08
tags: mysql
---



mysql 的启动和关闭方式, 根据mysql安装的不同,有个几种不同的方式.

1. mysql安装到了系统,提供GUI等方式, 例如mysql for macos的安装系统.

   这种方式情况下, 只需要在相应的服务里, 点击启动或或者关闭就好.

   这是最简单的一种.

2. mysql提供相应的启动和停止脚本并且已经集成到相应的系统服务中,只是这些服务,一般需要cli方式调用,并没有提供GUI的方式.  典型的比如, mysql for linux, 提供的 rpm或者deb安装包.

   在这些安装包后, mysql已经被加入到系统服务中, 我们可以通过以下命令用于启停mysql服务

   ```bash
   service mysql start
   service mysql stop
   ```
   <!-- more -->
   ​ 具体命令输出,如下所示

   ```bash
   root@1a705fa0f293:/home/eharry/bin# service mysql status
    * MySQL is stopped.
   root@1a705fa0f293:/home/eharry/bin# service mysql start
    * Starting MySQL database server mysqld
   No directory, logging in with HOME=/
      ...done.
   root@1a705fa0f293:/home/eharry/bin# service mysql status
    * /usr/bin/mysqladmin  Ver 8.42 Distrib 5.7.20, for Linux on x86_64
   Copyright (c) 2000, 2017, Oracle and/or its affiliates. All rights reserved.

   Oracle is a registered trademark of Oracle Corporation and/or its
   affiliates. Other names may be trademarks of their respective
   owners.

   Server version          5.7.20-0ubuntu0.16.04.1
   Protocol version        10
   Connection              Localhost via UNIX socket
   UNIX socket             /var/run/mysqld/mysqld.sock
   Uptime:                 5 sec

   Threads: 1  Questions: 9  Slow queries: 0  Opens: 105  Flush tables: 1  Open tables: 98  Queries per second avg: 1.800
   root@1a705fa0f293:/home/eharry/bin# service mysql stop
    * Stopping MySQL database server mysqld
      ...done.
   root@1a705fa0f293:/home/eharry/bin# service mysql status
    * MySQL is stopped.
   ```

   如果稍微看下, mysql的service的实现方式,我们就知道

   在/etc/init.d/mysql中,可以看到start和stop的实现

   ```bash
     'start')
           sanity_checks;
           # Start daemon
           log_daemon_msg "Starting MySQL database server" "mysqld"
           if mysqld_status check_alive nowarn; then
              log_progress_msg "already running"
              log_end_msg 0
           else
               # Could be removed during boot
               test -e /var/run/mysqld || install -m 755 -o mysql -g root -d /var/run/mysqld

               # Start MySQL!
               su - mysql -s /bin/sh -c "/usr/bin/mysqld_safe > /dev/null 2>&1 &"

               # 6s was reported in #352070 to be too few when using ndbcluster
               # 14s was reported in #736452 to be too few with large installs
               for i in $(seq 1 30); do
                   sleep 1
                   if mysqld_status check_alive nowarn ; then break; fi
                   log_progress_msg "."
               done
               if mysqld_status check_alive warn; then
                   log_end_msg 0
                   # Now start mysqlcheck or whatever the admin wants.
                   output=$(/etc/mysql/debian-start)
                   [ -n "$output" ] && log_action_msg "$output"
               else
                   log_end_msg 1
                   log_failure_msg "Please take a look at the syslog"
               fi
           fi
           ;;

   ```

   mysqld的启动, 实际上是启动了mysqld_safe这个程序, 而这个mysqld_safe又是一个脚本

   ```bash
   root@1a705fa0f293:/home/eharry/bin# file /usr/bin/mysqld_safe
   /usr/bin/mysqld_safe POSIX shell script, ASCII text executable
   ```

   mysqld_safe又是一层对mysqld启动过程的封装,不过最终会调用到mysqld,并启动.

   而service mysql stop的实现方式,又是使用了另一中方式

   ```bash
     'stop')
           # * As a passwordless mysqladmin (e.g. via ~/.my.cnf) must be possible
           # at least for cron, we can rely on it here, too. (although we have
           # to specify it explicit as e.g. sudo environments points to the normal
           # users home and not /root)
           log_daemon_msg "Stopping MySQL database server" "mysqld"
           if ! mysqld_status check_dead nowarn; then
             set +e
             shutdown_out=`$MYADMIN shutdown 2>&1`; r=$?
             set -e
             if [ "$r" -ne 0 ]; then
               log_end_msg 1
               [ "$VERBOSE" != "no" ] && log_failure_msg "Error: $shutdown_out"
               log_daemon_msg "Killing MySQL database server by signal" "mysqld"
               killall -15 mysqld
               server_down=
               for i in 1 2 3 4 5 6 7 8 9 10; do
                 sleep 1
                 if mysqld_status check_dead nowarn; then server_down=1; break; fi
               done
             if test -z "$server_down"; then killall -9 mysqld; fi
             fi
           fi

           if ! mysqld_status check_dead warn; then
             log_end_msg 1
             log_failure_msg "Please stop MySQL manually and read /usr/share/doc/mysql-server-5.7/README.Debian.gz!"
             exit -1
           else
             log_end_msg 0
           fi
           ;;
   ```


​       可以看出, 使用的是mysqladmin shutdown 来关闭mysqld程序的.

```bash
MYADMIN="/usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf"
```

```bash
root@1a705fa0f293:/home/eharry/bin# file /usr/bin/mysqladmin
/usr/bin/mysqladmin: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, BuildID[sha1]=fc5111601657aa5c489fab09bb1277db8cbad40f, stripped
```



​      总结: 在linux等使用rpm安装的mysql环境, 外部使用

```bash
service mysql start
service mysql stop
```

来开关mysql, 但内部实际上使用的是

```bash
mysqld [options]
mysqladmin shutdown [options]

```

来启动和关闭mysql服务器



3. 最后一种启动和关闭mysql的方式,也就是上文分析到最后的, 直接使用mysqld和mysqladmin来操作数据库

   ```bash
   mysqld --defaults-file=/home/eharry/app/mysql/data/conf/my.cnf &
   mysqladmin shutdown -u root -p -S /home/eharry/app/mysql/data2/mysql.sock
   ```

4. mysql官方还提供了一种方法用于管理mysql集群,这就是**mysqld_multi**

   这个工具用来管理批量的启动mysql和关闭mysqlc操作. 

   具体内容,可参考mysql官方文档




一般在实际应用中 2 的方式用的最多, mysql已经提供了很好的启动脚本, 不需要我们直接调用底层的mysqld和mysqladmin程序用于控制mysql进程.

