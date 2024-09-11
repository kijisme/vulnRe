#!/usr/bin/env python3
# -*- coding: utf-8 -*-

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

import json
import sys
import re

SCALE=1000
A = {}
B = {}
C = {}
i = 0

files = sys.argv[1:]

# Sorting files based on experiment tag
# (see TAGS definition for correct order)
TAGS = ("NoDegrade", "Degrade", "HyperDegrade")
sorted_files = [0] * 3
for fname in files:
    for i,t in enumerate(TAGS):
        if re.match(r".*_%s_.*" % t, fname):
            sorted_files[i] = fname
            break
    else:
        print("[ERROR] Unknown experiment tag in file: %s" % fname)
        exit(1)

files = sorted_files

for f in files:
    with open(f) as fp:
        data = json.load(fp)
    offsets = {}
    for d in data:
        benchmark = d["benchmark"]
        hostname = d["hostname"]
        cachemisses = d["cache-misses"]
        cycles = d["cycles"]
        CPU_D = d["CPU_D"]
        CPU_V = d["CPU_V"]
        offset = d["offset"]
        if benchmark not in offsets: offsets[benchmark] = []
        if offset not in offsets[benchmark]:
            offsets[benchmark].append(offset)
            continue
        if benchmark not in A: A[benchmark] = []
        if benchmark not in B: B[benchmark] = []
        if benchmark not in C: C[benchmark] = []
        if i == 0: A[benchmark].append(cycles)
        if i == 1: B[benchmark].append(cycles)
        if i == 2: C[benchmark].append(cycles)
    i += 1

print("""
|       benchmark      | NoDegrade |       Degrade      |      HyperDegrade    |
|----------------------|-----------|--------------------|----------------------|""")

for benchmark in A:
    A[benchmark].sort()
    B[benchmark].sort()
    C[benchmark].sort()
    med_A = A[benchmark][len(A[benchmark]) // 2]
    try: med_B = B[benchmark][len(B[benchmark]) // 2]
    except: med_B = 0
    try: med_C = C[benchmark][len(C[benchmark]) // 2]
    except: med_C = 0
    ratio_B = med_B / float(med_A)
    ratio_C = med_C / float(med_A)
    print('| %s |   %s | %s (%sx) | %s (%sx) |' % (benchmark.ljust(len("sglib-arrayquicksort"), " "),
                                                 ("%d" % (med_A // SCALE)).rjust(7, " "),
                                                 ("%d" % (med_B // SCALE)).rjust(9, " "),
                                                 ("%.1f" % ratio_B).rjust(5, " "),
                                                 ("%d" % (med_C // SCALE)).rjust(10, " "),
                                                 ("%.1f" % ratio_C).rjust(6, " "),))
