#!/bin/bash
set -e
cd "$(dirname "$0")"

cleanup() {
    rm -f c/day4_part1
    rm -f odin/day4_single odin/day4_parallel
    rm -f odin/single/input.txt odin/parallel/input.txt
    rm -f bench_part1_results.md
}

trap cleanup EXIT

echo "Day 4 Part 1 Benchmark"
echo

# Setup input symlinks
for dir in odin/single odin/parallel; do
    ln -sf ../../input.txt "$dir/input.txt" 2>/dev/null || true
done

# Build C
echo "Building C..."
(cd c && cc -std=c89 -O3 -o day4_part1 day4_part1.c 2>/dev/null)

# Build Odin
echo "Building Odin..."
(cd odin && odin build single -o:speed -out:day4_single 2>/dev/null)
(cd odin && odin build parallel -o:speed -out:day4_parallel 2>/dev/null)

# Verify outputs
echo
echo "Verifying outputs..."
C_P1=$(cd c && ./day4_part1)
ODIN_SINGLE=$(cd odin && ./day4_single)
ODIN_PARALLEL=$(cd odin && ./day4_parallel)
PY_P1=$(cd python && python3 day4_part1.py)

echo "C:             $C_P1"
echo "Odin Single:   $ODIN_SINGLE"
echo "Odin Parallel: $ODIN_PARALLEL"
echo "Python:        $PY_P1"
echo

# Get absolute paths for hyperfine
C_BIN="$(pwd)/c/day4_part1"
ODIN_SINGLE_BIN="$(pwd)/odin/day4_single"
ODIN_PARALLEL_BIN="$(pwd)/odin/day4_parallel"
PY_SCRIPT="$(pwd)/python/day4_part1.py"

hyperfine \
    --warmup 50 \
    --runs 500 \
    --export-markdown bench_part1_results.md \
    -n "C" "cd c && ./day4_part1" \
    -n "Odin (single)" "cd odin && ./day4_single" \
    -n "Odin (parallel)" "cd odin && ./day4_parallel" \
    -n "Python" "cd python && python3 day4_part1.py"
