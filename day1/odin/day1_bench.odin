package main

import "core:fmt"
import "core:time"
import "core:slice"
import "core:c/libc"

ITERATIONS :: 1000

main :: proc() {
	times := make([]f64, ITERATIONS)
	defer delete(times)

	fmt.println("Running day1 solution", ITERATIONS, "times...")

	for i in 0..<ITERATIONS {
		start := time.now()
		libc.system("./odin/day1 > /dev/null 2>&1")
		elapsed := time.duration_nanoseconds(time.since(start))
		times[i] = f64(elapsed)
	}

	// Get one run with output
	fmt.println("\nSolution output:")
	libc.system("./odin/day1")

	slice.sort(times[:])

	total: f64 = 0
	for t in times {
		total += t
	}

	avg := total / ITERATIONS
	median := times[ITERATIONS / 2]
	min_t := times[0]
	max_t := times[ITERATIONS - 1]
	p99 := times[int(ITERATIONS * 0.99)]

	fmt.printf("\nBenchmark (%d iterations):\n", ITERATIONS)
	fmt.printf("  Min:    %.3f ms\n", min_t / 1_000_000)
	fmt.printf("  Max:    %.3f ms\n", max_t / 1_000_000)
	fmt.printf("  Avg:    %.3f ms\n", avg / 1_000_000)
	fmt.printf("  Median: %.3f ms\n", median / 1_000_000)
	fmt.printf("  P99:    %.3f ms\n", p99 / 1_000_000)
}
