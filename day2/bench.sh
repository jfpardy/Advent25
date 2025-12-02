#!/bin/bash
set -e
cd "$(dirname "$0")"

cleanup() {
    rm -f c/day2 c/input.txt
    rm -f odin/day2 odin/input.txt
    rm -f python/input.txt
    rm -f asm/day2 asm/day2.o asm/input.txt
    rm -f bench_results.md
}

trap cleanup EXIT

echo "Day 2 Benchmark"
echo

for dir in python c odin asm; do
    ln -sf ../input.txt "$dir/input.txt" 2>/dev/null || true
done

(cd c && cc -std=c89 -O3 -o day2 day2.c -lm 2>/dev/null)

(cd odin && odin build . -file -o:speed -out:day2)

(cd asm && as -o day2.o day2.s && ld -o day2 day2.o -lSystem -syslibroot $(xcrun -sdk macosx --show-sdk-path) -e _main)


C_OUT=$(cd c && ./day2)
ODIN_OUT=$(cd odin && ./day2)
ASM_OUT=$(cd asm && ./day2)
PY1_OUT=$(cd python && python3 day2_part1.py)
PY2_OUT=$(cd python && python3 day2_part2.py)

echo "C:      $C_OUT"
echo "Odin:   $ODIN_OUT"
echo "ASM:    $ASM_OUT"
echo "Python: Part 1: $PY1_OUT / Part 2: $PY2_OUT"
echo

hyperfine \
    --warmup 100 \
    --runs 1500 \
    --export-markdown bench_results.md \
    --shell=none \
    -n "C" "c/day2" \
    -n "Odin" "odin/day2" \
    -n "ASM" "asm/day2" \
    -n "Python (p1)" "python3 python/day2_part1.py" \
    -n "Python (p2)" "python3 python/day2_part2.py"
