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

if [[ $2 == "small" ]];
then
    BENCHMARKS="bubblesort sglib-arraybinsearch ns"
else
    BENCHMARKS="aha-compress aha-mont64 bs bubblesort cnt compress cover crc crc32 ctl-stack ctl-string ctl-vector cubic dijkstra dtoa duff edn expint fac fasta fdct fibcall fir frac huffbench insertsort janne_complex jfdctint lcdnum levenshtein ludcmp matmult-float matmult-int mergesort miniz minver nbody ndes nettle-aes nettle-arcfour nettle-cast128 nettle-des nettle-md5 nettle-sha256 newlib-exp newlib-log newlib-mod newlib-sqrt ns nsichneu picojpeg prime qrduino qsort qurt recursion rijndael select sglib-arraybinsearch sglib-arrayheapsort sglib-arrayquicksort sglib-dllist sglib-hashtable sglib-listinsertsort sglib-listsort sglib-queue sglib-rbtree slre sqrt st statemate stb_perlin stringsearch1 strstr tarai template trio-snprintf trio-sscanf ud whetstone wikisort"
fi

# cpu pinning
CPU_D=999
CPU_V=999

L1=$(sort /sys/bus/cpu/devices/cpu*/topology/thread_siblings_list | uniq | tail -n1)
L2=$(sort /sys/bus/cpu/devices/cpu*/topology/thread_siblings_list | uniq | tail -n2 | head -n1)
P0=$(echo $L1 | cut -f1 -d,)
P1=$(echo $L1 | cut -f2 -d,)
P2=$(echo $L2 | cut -f1 -d,)
P3=$(echo $L2 | cut -f2 -d,)

if [[ $1 == "A" ]]; then CPU_V=$P3; CPU_D=-1;  EXP="NoDegrade";    fi
if [[ $1 == "B" ]]; then CPU_V=$P3; CPU_D=$P1; EXP="Degrade";      fi
if [[ $1 == "C" ]]; then CPU_V=$P3; CPU_D=$P2; EXP="HyperDegrade"; fi

if [ $CPU_D -eq 999 ]; then
    echo "DEBUG:ERROR:unrecognized option"
    exit 1
fi

echo "DEBUG:$EXP:CPU_V:$CPU_V:CPU_D:$CPU_D"

# need degrade binary
if [ ! -f degrade ]; then
    make clean
    make
fi

# need shared libs
if [ ! -f $DIR_BEEBS/aha-compress/libaha-compress.so ]; then
    ./build_shared.sh
fi

# JSON output
F_BENCH=$(mktemp -t bench_${HOSTNAME}_${EXP}_$(date +%Y-%m-%d-%H-%M-%S)_XXXXXXXX.json --tmpdir=.)

echo "[" > $F_BENCH

# loop through all benchmarks
for bench in $BENCHMARKS; do
    echo "DEBUG:INFO:RUN:bench:$bench" >&2
    BYTES=$(wc -c <"$DIR_BEEBS/$bench/lib$bench.so")
    BEST_CYCLES=0
    BEST_OFFSET=0
    BEST_ITS=17
    for (( offset = 0; $CPU_D >= 0 && offset < $BYTES; offset += 64 )); do
        ARR_CYCLES=()
        ARR_MISSES=()
        for (( i = 0; i < 3; i += 1 )); do
            killall -q degrade
            # start degrading offset
            taskset -c $CPU_D ./degrade $DIR_BEEBS/$bench/lib$bench.so $offset &
            disown $!
            # profile with perf stat
            arr=($(perf stat -e cache-misses -e cycles taskset -c $CPU_V $DIR_BEEBS/$bench/$bench 2>&1 | sed 's/,//g' | awk '/cache-misses|cycles/ {print $1}'))
            if [ ! ${#arr[@]} -eq 2 ]; then
                echo "DEBUG:ERROR:perf"
                exit 1
            fi
            if [ ! $CPU_D -eq -1 ]; then
                killall -q degrade
                wait $!
            fi
            ARR_CYCLES+=(${arr[1]})
            ARR_MISSES+=(${arr[0]})
        done
        if (( ${ARR_CYCLES[0]} > ${ARR_CYCLES[1]} )); then
            ARR_CYCLES=(${ARR_CYCLES[1]} ${ARR_CYCLES[0]} ${ARR_CYCLES[2]})
            ARR_MISSES=(${ARR_MISSES[1]} ${ARR_MISSES[0]} ${ARR_MISSES[2]})
        fi
        if (( ${ARR_CYCLES[0]} >= ${ARR_CYCLES[2]} )); then
            ARR_CYCLES=(${ARR_CYCLES[2]} ${ARR_CYCLES[0]} ${ARR_CYCLES[1]})
            ARR_MISSES=(${ARR_MISSES[2]} ${ARR_MISSES[0]} ${ARR_MISSES[1]})
        fi
        if (( ${ARR_CYCLES[1]} > ${ARR_CYCLES[2]} )); then
            ARR_CYCLES=(${ARR_CYCLES[0]} ${ARR_CYCLES[2]} ${ARR_CYCLES[1]})
            ARR_MISSES=(${ARR_MISSES[0]} ${ARR_MISSES[2]} ${ARR_MISSES[1]})
        fi
        # take the median
        echo "{\"benchmark\":\"$bench\",\"hostname\":\"$HOSTNAME\",\"cache-misses\":${ARR_MISSES[1]},\"cycles\":${ARR_CYCLES[1]},\"CPU_D\":$CPU_D,\"CPU_V\":$CPU_V,\"offset\":$offset}," >> $F_BENCH
        if (( ${ARR_CYCLES[1]} > $BEST_CYCLES )); then
            BEST_CYCLES=${ARR_CYCLES[1]}
            BEST_OFFSET=$offset
        fi
    done
    for (( i = 0; i < $BEST_ITS; i += 1 )); do
        killall -q degrade
        if [ ! $CPU_D -eq -1 ]; then
            # start degrading offset
            taskset -c $CPU_D ./degrade $DIR_BEEBS/$bench/lib$bench.so $BEST_OFFSET &
            disown $!
        fi
        # profile with perf stat
        arr=($(perf stat -e cache-misses -e cycles taskset -c $CPU_V $DIR_BEEBS/$bench/$bench 2>&1 | sed 's/,//g' | awk '/cache-misses|cycles/ {print $1}'))
        if [ ! ${#arr[@]} -eq 2 ]; then
            echo "DEBUG:ERROR:perf"
            exit 1
        fi
        if [ ! $CPU_D -eq -1 ]; then
            killall -q degrade
            wait $!
        fi
        echo "{\"benchmark\":\"$bench\",\"hostname\":\"$HOSTNAME\",\"cache-misses\":${arr[0]},\"cycles\":${arr[1]},\"CPU_D\":$CPU_D,\"CPU_V\":$CPU_V,\"offset\":$BEST_OFFSET}," >> $F_BENCH
    done
done

echo "{\"benchmark\":\"dummy\",\"hostname\":\"$HOSTNAME\",\"cache-misses\":-1,\"cycles\":-1,\"CPU_D\":$CPU_D,\"CPU_V\":$CPU_V,\"offset\":-1}]" >> $F_BENCH
python3 -m json.tool $F_BENCH > .foo
mv .foo $F_BENCH
echo "--------------------------------------------"