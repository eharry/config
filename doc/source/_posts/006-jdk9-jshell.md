---
title: jdk9-jshell
date: 2017-10-07 11:32:27
tags: [jdk, jdk9, jshell]
---

简单描述jdk9-jshell初步用法:

<!-- more -->

### 启动jshell

``` java
sh-3.2# jshell
|  欢迎使用 JShell -- 版本 9
|  要大致了解该版本, 请键入: /help intro

jshell>
```

运行 /help intro

``` java
jshell> /help intro
|
|  intro
|
|  使用 jshell 工具可以执行 Java 代码, 从而立即获取结果。
|  您可以输入 Java 定义 (变量, 方法, 类, 等等), 例如:  int x = 8
|  或 Java 表达式, 例如:  x + x
|  或 Java 语句或导入。
|  这些小块的 Java 代码称为 '片段'。
|
|  这些 jshell 命令还可以让您了解和
|  控制您正在执行的操作, 例如:  /list
|
|  有关命令的列表, 请执行: /help
```

运行 /help
``` java
|       列出已声明变量及其值
|  /methods [<名称或 id>|-all|-start]
|       列出已声明方法及其签名
|  /types [<名称或 id>|-all|-start]
|       列出已声明的类型
|  /imports
|       列出导入的项
|  /exit
|       退出 jshell
|  /env [-class-path <路径>] [-module-path <路径>] [-add-modules <模块>] ...
|       查看或更改评估上下文
|  /reset [-class-path <路径>] [-module-path <路径>] [-add-modules <模块>]...
|       重启 jshell
|  /reload [-restore] [-quiet] [-class-path <路径>] [-module-path <路径>]...
|       重置和重放相关历史记录 -- 当前历史记录或上一个历史记录 (-restore)
|  /history
|       您键入的内容的历史记录
|  /help [<command>|<subject>]
|       获取 jshell 的相关信息
|  /set editor|start|feedback|mode|prompt|truncation|format ...
|       设置 jshell 配置信息
|  /? [<command>|<subject>]
|       获取 jshell 的相关信息
|  /!
|       重新运行上一个片段
|  /<id>
|       按 id 重新运行片段
|  /-<n>
|       重新运行前面的第 n 个片段
|
|  有关详细信息, 请键入 '/help', 后跟
|  命令或主题的名称。
|  例如 '/help /list' 或 '/help intro'。主题:
|
|  intro
|       jshell 工具的简介
|  shortcuts
|       片段和命令输入提示, 信息访问以及
|       自动代码生成的按键说明
|  context
|       /env /reload 和 /reset 的评估上下文选项
```


### 进行简单的表达式计算

``` bash
jshell> 1+1
$3 ==> 2

jshell> 1*1
$4 ==> 1

jshell> 1-1
$5 ==> 0

jshell> 1/1
$6 ==> 1

jshell> 1+1*2
$7 ==> 3
```

如果算数运算/0， 仍然会抛异常

``` bash
jshell> 1/0
|  java.lang.ArithmeticException thrown: / by zero
|        at (#8:1)
```

尝试变量赋值

对于单行命令，行尾分号应该不是必须的。

``` bash
jshell> int a = 0;
a ==> 0

jshell> int a = 0
a ==> 0

jshell> a
a ==> 0

jshell> int b = 0
b ==> 0

jshell> b
b ==> 0
```

运行一个循环操作

``` bash
jshell> for(int i = 0; i < 3; i++) {
   ...>   System.out.println(i);
   ...> }
0
1
2

```

### jshell-list命令

``` bash
jshell> /help list
|
|  /list
|
|  显示前面带有片段 ID 的片段源。
|
|  /list
|       列出您键入的或使用 /open 读取的当前活动的代码片段
|
|  /list -start
|       列出自动评估的启动片段
|
|  /list -all
|       列出所有片段, 包括失败的片段, 覆盖的片段, 删除的片段和启动片段
|
|  /list <名称>
|       列出具有指定名称的片段 (特别是活动片段)
|
|  /list <id>
|       列出具有指定片段 ID 的片段
```

``` bash
jshell> /list

   1 : int a = 1;
   2 : a = 2
   3 : 2/a
   4 : a = 0
   5 : 2/a

jshell> /list -start

  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;

jshell> /list -all

  s1 : import java.io.*;
  s2 : import java.math.*;
  s3 : import java.net.*;
  s4 : import java.nio.file.*;
  s5 : import java.util.*;
  s6 : import java.util.concurrent.*;
  s7 : import java.util.function.*;
  s8 : import java.util.prefs.*;
  s9 : import java.util.regex.*;
 s10 : import java.util.stream.*;
   1 : int a = 1;
   2 : a = 2
   3 : 2/a
   4 : a = 0
   5 : 2/a

jshell> /list 3

   3 : 2/a
```

### jshell-edit

``` bash
jshell> /help edit
|
|  /edit
|
|  在外部编辑器中编辑源的片段。
|  使用 /set editor 可以设置要使用的编辑器。
|  如果尚未设置编辑器, 则将启动一个简单的编辑器。
|
|  /edit <名称>
|       编辑具有指定名称的片段 (特别是活动片段)
|
|  /edit <id>
|       编辑具有指定片段 id 的片段
|
|  /edit
|       编辑您键入或使用 /open 读取的当前活动的代码片段

```

edit 实际上并没有修改历史的id2的内容，而是重新根据修改后的b=5的结果插入到/list最后一行.
而且这个修改很傻，会额外启动一个gui工具，这样，估计在纯字符环境里，不能使用了。
``` bash
jshell> /list 2

   2 : a = 2

jshell> /edit 2
b ==> 5

jshell> /list 2

   2 : a = 2

jshell> /list 10

  10 : b = 5;
```

### 总结:
jshell 还有很多高级功能，没有一一尝试。

不过个人感觉jshell没有自动补全，很多代码都得手写，还不如开个ide，写个unittest，试验语言新特性来得快。


### note:
jshell 还不好退出，起码在我的版本里，是被强制kill掉的。
