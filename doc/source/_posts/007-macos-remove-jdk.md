---
title: macos remove jdk
date: 2017-10-06 18:09:51
tags: [macos, jdk]
---


### 如何删除macos的jdk

本文介绍了如何在macos下删除jdk的手工操作。

<!-- more -->



#### 检查本机的java环境

``` bash
➜  blog which java
/usr/bin/java
➜  blog java -version
java version "1.8.0_131"
Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
```

#### 使用shell脚本确认这些文件是否存在

- 脚本如下
``` bash
bash-3.2$ cat checkJdk.sh
#!/bin/bash

ls -l /Library/Java/JavaVirtualMachines/jdk*
ls -l /Library/PreferencePanes/JavaControlPanel.prefPane
ls -l /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin
ls -l /Library/LaunchAgents/com.oracle.java.Java-Updater.plist
ls -l /Library/PrivilegedHelperTools/com.oracle.java.JavaUpdateHelper
ls -l /Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist
ls -l /Library/Preferences/com.oracle.java.Helper-Tool.plist
```

上面的文件，就是macos 关于java所在路径的具体文件，卸载方式很简单，只需要删除相关文件即可

- 检查相关文件夹下内容

```bash
ash-3.2$ sh checkJdk.sh
total 0
drwxrwxr-x  5 root  wheel  170  3 15  2017 Contents
lrwxr-xr-x  1 root  wheel  101 10  6 18:14 /Library/PreferencePanes/JavaControlPanel.prefPane -> /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/lib/deploy/JavaControlPanel.prefPane
total 0
drwxr-xr-x  10 root  wheel  340 10  6 18:14 Contents
lrwxr-xr-x  1 root  wheel  104 10  6 18:14 /Library/LaunchAgents/com.oracle.java.Java-Updater.plist -> /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/com.oracle.java.Java-Updater.plist
ls: /Library/PrivilegedHelperTools/com.oracle.java.JavaUpdateHelper: No such file or directory
lrwxr-xr-x  1 root  wheel  103 10  6 18:14 /Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist -> /Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Resources/com.oracle.java.Helper-Tool.plist
-rw-r--r--  1 root  wheel  88 10  6 18:14 /Library/Preferences/com.oracle.java.Helper-Tool.plist
```

- 手动删除相关文件，或者执行删除脚本删除相关文件

删除脚本如下

```bash
sh-3.2# cat rmJdk.sh
#!/bin/bash

rm -rf /Library/Java/JavaVirtualMachines/jdk*
rm -rf /Library/PreferencePanes/JavaControlPanel.prefPane
rm -rf /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin
rm -rf /Library/LaunchAgents/com.oracle.java.Java-Updater.plist
rm -rf /Library/PrivilegedHelperTools/com.oracle.java.JavaUpdateHelper
rm -rf /Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist
rm -rf /Library/Preferences/com.oracle.java.Helper-Tool.plist
```

- 执行脚本 & 再次运行检查脚本

```bash
sh-3.2# sh rmJdk.sh
sh-3.2# sh checkJdk.sh
ls: /Library/Java/JavaVirtualMachines/jdk*: No such file or directory
ls: /Library/PreferencePanes/JavaControlPanel.prefPane: No such file or directory
ls: /Library/Internet Plug-Ins/JavaAppletPlugin.plugin: No such file or directory
ls: /Library/LaunchAgents/com.oracle.java.Java-Updater.plist: No such file or directory
ls: /Library/PrivilegedHelperTools/com.oracle.java.JavaUpdateHelper: No such file or directory
ls: /Library/LaunchDaemons/com.oracle.java.Helper-Tool.plist: No such file or directory
ls: /Library/Preferences/com.oracle.java.Helper-Tool.plist: No such file or directory
```

- 手动查找java程序，看是否能运行成功

```bash
sh-3.2# java -version
No Java runtime present, requesting install.
```