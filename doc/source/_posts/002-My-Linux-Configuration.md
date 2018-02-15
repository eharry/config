---
title: My Linux Configuration
date: 2017-10-06 16:20:01
tags: [Linux, configuration]
---

###  收集linux配置

- screenrc
- bashrc
- vimrc (todo)
- ctags/cscope (todo)

<!-- more -->

### screenrc
``` bash
caption always "%{= kw}%-w%{= kG}%{+b}[%n %t]%{-b}%{= kw}%+w %= %{g}%H%{-}"
defscrollback 10000
```

### bashrc

- copy from http://blog.csdn.net/ly890700/article/details/52851974

``` bash
sh-3.2# cat ~/.bashrc
alias wl='ll | wc -l'
alias ll='ls -l'
alias lh='ls -lh'
alias grep='grep -i --color' #用颜色标识，更醒目；忽略大小写
alias vi=vim
# alias c='clear'  # 快速清屏
# alias p='pwd'
# 进入目录并列出文件，如 cdl ../conf.d/
cdl() { cd "$@" && pwd ; ls -alF; }
alias .1="cdl .."
alias .2="cd ../.."   # 快速进入上上层目录
alias .3="cd ../../.."
alias .4="cd ../../.."
alias cd..='cdl ..'
# alias cp="cp -iv"      # interactive, verbose
# alias rm="rm -i"      # interactive
# alias mv="mv -iv"       # interactive, verbose
alias psg='\ps aux | grep -v grep | grep --color' # 查看进程信息
alias hg='history|grep'
alias netp='netstat -tulanp'  # 查看服务器端口连接信息
alias lvim="vim -c \"normal '0\""  # 编辑vim最近打开的文件
#alias tf='tail -f '  # 快速查看文件末尾输出
# 自动在文件末尾加上 .bak-日期 来备份文件，如 bu nginx.conf
bak() { cp "$@" "$@.bak"-`date +%y%m%d`; echo "`date +%Y-%m-%d` backed up $PWD/$@"; }
# 级联创建目录并进入，如 mcd a/b/c
mcd() { mkdir -p $1 && cd $1 && pwd ; }
# 查看去掉#注释和空行的配置文件，如 nocomm /etc/squid/squid.conf
alias nocomm='grep -Ev '\''^(#|$)'\'''
# 快速根据进程号pid杀死进程，如 psid tomcat， 然后 kill9 两个tab键提示要kill的进程号
alias kill9='kill -9';
psid() {
  [[ ! -n ${1} ]] && return;   # bail if no argument
  pro="[${1:0:1}]${1:1}";      # process-name –> [p]rocess-name (makes grep better)
  ps axo pid,user,command | grep -v grep |grep -i --color ${pro};   # show matching processes
  pids="$(ps axo pid,user,command | grep -v grep | grep -i ${pro} | awk '{print $1}')";   # get pids
  complete -W "${pids}" kill9     # make a completion list for kk
}
# 解压所有归档文件工具
function extract {
 if [ -z "$1" ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz>"
 else
    if [ -f $1 ] ; then
        # NAME=${1%.*}
        # mkdir $NAME && cd $NAME
        case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.tar.xz)    tar xvJf $1    ;;
          *.lzma)      unlzma $1      ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       unrar x -ad $1 ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *.xz)        unxz $1        ;;
          *.exe)       cabextract $1  ;;
          *)           echo "extract: '$1' - unknown archive method" ;;
        esac
    else
        echo "$1 - file does not exist"
    fi
fi
}
# 其它你自己的命令
alias nginxreload='sudo /usr/local/nginx/sbin/nginx -s reload'
```




