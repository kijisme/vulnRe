# Summary

This document is for reproducing one of the research results from
[the paper](https://arxiv.org/abs/2101.01077)
"HyperDegrade: From GHz to MHz Effective CPU Frequencies", to appear at the
31st [USENIX Security Symposium](https://www.usenix.org/conference/usenixsecurity22/)
(USENIX Sec 2022).

It is for reproducing the results in Section 4 of the paper,
including Tables 8-9.

The instructions assume the root directory of the archive you
are reading now is as follows.

```
cd /path/to/hyperd/
```

# Requirements on Ubuntu

```
sudo apt install git build-essential python3 linux-tools-common linux-tools-generic linux-tools-`uname -r`
```

## Enable perf

```
echo "-1" | sudo tee /proc/sys/kernel/perf_event_paranoid
```

# Building BEEBS benchmark suite

You only have to build the binaries once.

```
cd /path/to/hyperd/
git clone https://github.com/mageec/beebs.git
```

At the time of this writing, the most recent commit
on the `master` branch of the `beebs` repo is:
`049ded9f3aeb5591f553879d3a0376b8614e9422`

Build all benchmarks as follows. (Linking statically.)

```
cd /path/to/hyperd/beebs/
patch -p1 < ../beebs.patch
./configure --build=x86_64
make MAKEINFO=true
```

## Shared parts

There's a post-processing script to build as a shared library.

```
cd /path/to/hyperd/
./build_shared.sh
```

# Build degrade tooling

```
cd /path/to/hyperd/
make clean
make
```

You should now have the `degrade` binary.

# Benchmark experiments

Running all experiments takes a significant amount of time (~50h),
especially for _Degrade_ and _HyperDegrade_ strategies.

You can run a partial experiment that should take 2 hours to complete
using: `run_all.sh small`.

For full experiment run: `run_all.sh`.

Benchmark results will appear in the `bench_*.json` files.

## Run experiment

You can also execute the experiments on demand.

For the baseline experiment with no degrading (_NoDegrade_):

```
cd /path/to/hyperd/
./degrade.sh A
```

To degrade from a different physical core (_Degrade_):

```
cd /path/to/hyperd/
./degrade.sh B
```

To degrade from the same physical core (_HyperDegrade_):

```
cd /path/to/hyperd/
./degrade.sh C
```

# Parse results and compare

After completing the experiment we should have _**three**_ json files,
one for each degrade strategy. If no other json files are in `path/`
you can parse and see the results using:

```
cd /path/to/hyperd/
python3 compare.py path/bench*.json
```

# Credits

## Authors

* Alejandro Cabrera Aldaya (Tampere University, Tampere, Finland)
* Billy Bob Brumley (Tampere University, Tampere, Finland)

## Funding

* This project has received funding from the European Research Council (ERC)
under the European Union's Horizon 2020 research and innovation programme
(grant agreement No 804476).
* Supported in part by CSIC's i-LINK+ 2019
"Advancing in cybersecurity technologies" (Ref. LINKA20216).

# License

This work is released under the MIT License.