#!/bin/sh
# generate tag file for lookupfile plugin

rm -rf cscope.in.out cscope.out cscope.po.out filenametags files tags

echo -e "!_TAG_FILE_SORTED\t2\t/2=foldcase/" > filenametags
gfind . -not -regex '.*\.\(png\|gif\)' -type f -printf "%f\t%p\t1\n" | sort -f >> filenametags

gfind . -name "*.h" -o -name "*.c" -o -name "*.cc" -o -name "*.java" > files


ctags  -R --c++-kinds=+p --fields=+iaS --extras=+q --language-force=C++ -L -< files

cscope -bkq -i files
