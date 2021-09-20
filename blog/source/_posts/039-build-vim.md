---
title: 039-build-vim
date: 2021-07-31 16:29:33
tags:
---

```bash
./configure --prefix=/usr/local \
  --with-features=huge \
  --enable-fail-if-missing \
  --enable-luainterp \
  --with-lua-prefix=/usr \
  --enable-perlinterp \
  --enable-pythoninterp=yes \
  --enable-python3interp=yes \
  --enable-rubyinterp \
  --with-ruby-command=ruby \
  --enable-cscope \
  --enable-terminal \
  --enable-autoservername \
  --enable-multibyte \
  --enable-xim \
  --enable-fontset \
  --enable-gnome-check \
  --with-tlib=ncurses
```

```bash
make
```

```bash
make install
```

