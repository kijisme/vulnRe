/**
 * The MIT License (MIT)
 *
 * Copyright (c) 2021 Alejandro Cabrera Aldaya, Billy Bob Brumley
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <sys/mman.h>
#include <sys/fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "HyperDegrade/degrade.h"

int main(int argc, char *argv[]) {

    if (argc != 3) {
        printf("Usage: %s </path/to/library.so> <address_offset_base_10>\n", argv[0]);
        return 1;
    }

    /* load shlib */
    char *name = argv[1];
    int fd = open(name, O_RDONLY);

    if (fd < 3) {
        printf("Error: Failed to load shared library\n");
        return 2;
    }

    uint64_t base_addr = (uint64_t)mmap(0, 64*1024*1024, PROT_READ, MAP_SHARED, fd, 0);

    if (base_addr == -1 || base_addr == 0) {
        printf("Error: failed to mmap shared library\n");
        return 2;
    }

    /* degrade in an infinite loop */
    uint64_t addr1 = 0;
    //assert(sscanf(argv[2], "%lx", &addr1) == 1);
    assert(sscanf(argv[2], "%ld", &addr1) == 1);

    x64_degrade(base_addr + addr1);

    return 0;
}
