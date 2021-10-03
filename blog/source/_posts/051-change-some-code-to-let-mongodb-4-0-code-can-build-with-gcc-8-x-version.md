---
title: 051-change some code to let mongodb 4.0 code can build with gcc-8.x version
date: 2021-10-04 00:41:09
tags:
---

### 051-change some code to let mongodb 4.0 code can build with gcc-8.x version

* mongodb 4.0 版本，一直不能在高的 gcc 版本运行，通过屏蔽一些编译错误，可以让 高版本的 gcc 编译 4.0 的代码，从而保证所有运行环境都是一套编译系统。
* 相关diff 如下：
  * https://github.com/eharry/mongo/commit/77b77da59ecf1c7e70bc81d27f1dff91e5405616

