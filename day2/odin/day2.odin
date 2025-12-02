package main

import "core:fmt"
import "core:os"
import "core:mem"

@(rodata)
POW10 := [11]u64{1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, 10000000000}

compute_mult :: #force_inline proc "contextless" (d, k: int) -> u64 {
	result: u64 = 0
	p: u64 = 1
	#no_bounds_check for _ in 0 ..< k {
		result += p
		p *= POW10[d]
	}
	return result
}

MAX_INVALID :: 8192
HASH_SIZE :: 16384
HASH_MASK :: HASH_SIZE - 1

HashSet :: struct {
	slots: [HASH_SIZE]u64,
	valid: [HASH_SIZE]bool,
	items: [MAX_INVALID]u64,
	count: int,
}

@(require_results)
hash :: #force_inline proc "contextless" (x: u64) -> u64 {
	h := x
	h ~= h >> 33
	h *= 0xff51afd7ed558ccd
	h ~= h >> 33
	h *= 0xc4ceb9fe1a85ec53
	h ~= h >> 33
	return h
}

insert :: #force_inline proc "contextless" (hs: ^HashSet, val: u64) {
	idx := hash(val) & HASH_MASK
	#no_bounds_check for {
		if !hs.valid[idx] {
			hs.valid[idx] = true
			hs.slots[idx] = val
			hs.items[hs.count] = val
			hs.count += 1
			return
		}
		if hs.slots[idx] == val do return
		idx = (idx + 1) & HASH_MASK
	}
}

num_digits :: #force_inline proc "contextless" (n: u64) -> int {
	if n < 10 do return 1
	if n < 100 do return 2
	if n < 1000 do return 3
	if n < 10000 do return 4
	if n < 100000 do return 5
	if n < 1000000 do return 6
	if n < 10000000 do return 7
	if n < 100000000 do return 8
	if n < 1000000000 do return 9
	if n < 10000000000 do return 10
	return 11
}

ceil_div :: #force_inline proc "contextless" (a, b: u64) -> u64 {
	return (a + b - 1) / b
}

part1_range :: proc "contextless" (low, high: u64) -> u64 {
	total: u64 = 0

	#no_bounds_check for k := 1; k <= 5; k += 1 {
		multiplier := POW10[k] + 1
		base_min := k > 1 ? POW10[k - 1] : 1
		min_doubled := base_min * multiplier

		if min_doubled > high do break

		base_max := POW10[k] - 1
		min_base := ceil_div(low, multiplier)
		max_base := high / multiplier

		if min_base < base_min do min_base = base_min
		if max_base > base_max do max_base = base_max

		if min_base <= max_base {
			count := max_base - min_base + 1
			base_sum := (min_base + max_base) * count / 2
			total += base_sum * multiplier
		}
	}
	return total
}

part2_range :: proc "contextless" (low, high: u64, hs: ^HashSet) {
	max_d := num_digits(high)

	#no_bounds_check for d := 1; d <= 5 && d <= max_d; d += 1 {
		base_min := d > 1 ? POW10[d - 1] : 1
		base_max := POW10[d] - 1

		for k := 2; d * k <= 11; k += 1 {
			multiplier := compute_mult(d, k)

			min_base := ceil_div(low, multiplier)
			max_base := high / multiplier

			if min_base < base_min do min_base = base_min
			if max_base > base_max do max_base = base_max

			for base := min_base; base <= max_base; base += 1 {
				insert(hs, base * multiplier)
			}
		}
	}
}

parse_u64 :: #force_inline proc "contextless" (data: [^]u8, i: ^int, n: int) -> u64 {
	val: u64 = 0
	#no_bounds_check for i^ < n {
		c := data[i^]
		d := c - '0'
		if d > 9 do break
		val = val * 10 + u64(d)
		i^ += 1
	}
	return val
}

solve :: proc "contextless" (data: [^]u8, n: int) -> (u64, u64) {
	part1: u64 = 0
	hs: HashSet
	mem.zero(&hs.valid, size_of(hs.valid))
	hs.count = 0

	i := 0
	#no_bounds_check for i < n {
		for i < n && (data[i] < '0' || data[i] > '9') {
			i += 1
		}
		if i >= n do break

		low := parse_u64(data, &i, n)
		i += 1  // skip '-'
		high := parse_u64(data, &i, n)

		part1 += part1_range(low, high)
		part2_range(low, high, &hs)
	}

	part2: u64 = 0
	#no_bounds_check for j in 0 ..< hs.count {
		part2 += hs.items[j]
	}

	return part1, part2
}

main :: proc() {
	data, ok := os.read_entire_file("input.txt")
	if !ok {
		fmt.eprintln("failed to read input.txt")
		return
	}
	defer delete(data)

	p1, p2 := solve(raw_data(data), len(data))
	fmt.printf("Part 1: %d\nPart 2: %d\n", p1, p2)
}
