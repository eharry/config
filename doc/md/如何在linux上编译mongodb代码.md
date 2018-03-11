

如何在linux上编译mongodb代码



* 下载并解压mongodb代码到目录

* 仔细阅读 ${code}/doc/building.md

  ```txt
  Building MongoDB
  ================

  To build MongoDB, you will need:

  * A modern C++ compiler. One of the following is required.
      * GCC 5.4.0 or newer
      * Clang 3.8 (or Apple XCode 8.3.2 Clang) or newer
      * Visual Studio 2015 Update 3 or newer (See Windows section below for details)
  * Python 2.7.x and Pip modules:
    * pyyaml
    * typing

  MongoDB supports the following architectures: arm64, ppc64le, s390x, and x86-64.
  More detailed platform instructions can be found below.

  MongoDB Tools
  --------------

  The MongoDB command line tools (mongodump, mongorestore, mongoimport, mongoexport, etc)
  have been rewritten in [Go](http://golang.org/) and are no longer included in this repository.

  The source for the tools is now available at [mongodb/mongo-tools](https://github.com/mongodb/mongo-tools).

  Python Prerequisites
  ---------------

  In order to build MongoDB, Python 2.7.x is required, and several Python modules. To install
  the required Python modules, run:

      $ pip2 install -r buildscripts/requirements.txt

  Note: If the `pip2` command is not available, `pip` without a suffix may be the pip command
  associated with Python 2.7.x.

  SCons
  ---------------

  For detail information about building, please see [the build manual](https://github.com/mongodb/mongo/wiki/Build-Mongodb-From-Source)

  If you want to build everything (mongod, mongo, tests, etc):

      $ python2 buildscripts/scons.py all

  If you only want to build the database:

      $ python2 buildscripts/scons.py mongod

  To install

      $ python2 buildscripts/scons.py --prefix=/opt/mongo install

  Please note that prebuilt binaries are available on [mongodb.org](http://www.mongodb.org/downloads) and may be the easiest way to get started.

  SCons Targets
  --------------

  * mongod
  * mongos
  * mongo
  * core (includes mongod, mongos, mongo)
  * all

  Debian/Ubuntu
  --------------

  To install dependencies on Debian or Ubuntu systems:
  # aptitude install build-essential
  # aptitude install libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-thread-dev

  To run tests as well, you will need PyMongo:
  ```

* 简单的说，运行以下命令安装编译环境 lib库



  ```bash
  apt install libboost-filesystem-dev libboost-program-options-dev libboost-system-dev libboost-thread-dev
  ```

* 除了上面的库，还需要安装python相关的一些库， python-pymongo，pip, setup tools, typing, pyyaml,cheetah3。
  * apt install python-pymongo
  * 从https://pypi.python.org/pypi 搜索并下载剩下的python安装包，将包解压后，进入解压后路径， 执行 python setup.py install 命令，即可安装对应的python模块。


* 运行命令，build mongodb进程

  * Mongodb 使用scons构建， 里面有几个target，分别是
    * mongod
    * mongos
    * mongo
    * core (includes mongo, mongos, mongo)
    * all

  * 编译最基本的mongod, 命令如下

    ```bash
    python2 buildscripts/scons.py mongod -j 4
    ```

    ​编译速度取决于电脑性能， -j 4，表示同时开启的编译线程个数。如果你服务器性能够好，可以增大这个值。  一般来说，第一次编译需要20分钟到60分钟不等。