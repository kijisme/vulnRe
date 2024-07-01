#!/bin/bash

# The MIT License (MIT)
#
# Copyright (c) 2021 Alejandro Cabrera Aldaya, Billy Bob Brumley
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

DIR_BEEBS=$PWD/beebs/src

# these benchmarks are not recognized with autoconf / compiled: ctl matmult sglib-arraysort trio
# play with this variable if you want to restrict the benchmark suite for testing
BENCHMARKS="aha-compress aha-mont64 bs bubblesort cnt compress cover crc crc32 ctl-stack ctl-string ctl-vector cubic dijkstra dtoa duff edn expint fac fasta fdct fibcall fir frac huffbench insertsort janne_complex jfdctint lcdnum levenshtein ludcmp matmult-float matmult-int mergesort miniz minver nbody ndes nettle-aes nettle-arcfour nettle-cast128 nettle-des nettle-md5 nettle-sha256 newlib-exp newlib-log newlib-mod newlib-sqrt ns nsichneu picojpeg prime qrduino qsort qurt recursion rijndael select sglib-arraybinsearch sglib-arrayheapsort sglib-arrayquicksort sglib-dllist sglib-hashtable sglib-listinsertsort sglib-listsort sglib-queue sglib-rbtree slre sqrt st statemate stb_perlin stringsearch1 strstr tarai template trio-snprintf trio-sscanf ud whetstone wikisort"
#BENCHMARKS="crc32 stringsearch1"

# loop through all benchmarks
for bench in $BENCHMARKS; do
    echo "DEBUG:INFO:BUILD:bench:$bench"
    cd $DIR_BEEBS/$bench/
    rm -f $bench
    OBJECTS=$(ls *.o)
    cc $OBJECTS -shared -o lib$bench.so
    cc -o $bench ../../support/.libs/libsupport.a -Wl,-rpath=$PWD -L. -l$bench -lm
done
