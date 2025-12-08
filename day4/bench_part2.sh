#!/bin/bash
set -e
cd "$(dirname "$0")"

cleanup() {
    rm -f c/day4_part2
    rm -f odin/day4_part2_simple odin/day4_part2_opt
    rm -f odin/part2_simple/input.txt odin/part2_optimized/input.txt
    rm -f bench_part2_results.md
}

trap cleanup EXIT

echo "Day 4 Part 2 Benchmark"
echo

# Setup input symlinks
for dir in odin/part2_simple odin/part2_optimized; do
    ln -sf ../../input.txt "$dir/input.txt" 2>/dev/null || true
done

# Build C
echo "Building C..."
(cd c && cc -std=c89 -O3 -o day4_part2 day4_part2.c 2>/dev/null)

# Build Odin
echo "Building Odin..."
(cd odin && odin build part2_simple -o:speed -out:day4_part2_simple 2>/dev/null)
(cd odin && odin build part2_optimized -o:speed -out:day4_part2_opt 2>/dev/null)

# Verify outputs
echo
echo "Verifying outputs..."
C_P2=$(cd c && ./day4_part2)
ODIN_P2_SIMPLE=$(cd odin && ./day4_part2_simple)
ODIN_P2_OPT=$(cd odin && ./day4_part2_opt)
PY_P2=$(cd python && python3 day4_part2.py)

echo "C:                  $C_P2"
echo "Odin (simple):      $ODIN_P2_SIMPLE"
echo "Odin (optimized):   $ODIN_P2_OPT"
echo "Python:             $PY_P2"
echo

hyperfine \
    --warmup 50 \
    --runs 500 \
    --export-markdown bench_part2_results.md \
    -n "C" "cd c && ./day4_part2" \
    -n "Odin (simple)" "cd odin && ./day4_part2_simple" \
    -n "Odin (optimized)" "cd odin && ./day4_part2_opt" \
    -n "Python" "cd python && python3 day4_part2.py"
