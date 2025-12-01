package main

import "core:fmt"
import "core:os"

solve :: proc "contextless" (instrs: [^]i16, n: int) -> (int, int) {
	pos := 50
	cnt1, cnt2 := 0, 0

	#no_bounds_check for i in 0..<n {
		v := int(instrs[i])

		if v > 0 {
			cnt2 += (pos + v) / 100
		} else if pos == 0 {
			cnt2 += (-v) / 100
		} else if -v >= pos {
			cnt2 += (-v - pos) / 100 + 1
		}

		pos = (pos + v) %% 100
		cnt1 += int(pos == 0)
	}
	return cnt1, cnt2
}

preparse :: proc(data: []u8) -> ([]i16, int) {
	instrs := make([]i16, 5000)
	count := 0
	i := 0
	n := len(data)

	#no_bounds_check for i < n {
		is_left := data[i] == 'L'
		i += 1

		val: i16 = 0
		for i < n {
			c := data[i]
			if c < '0' || c > '9' do break
			val = val * 10 + i16(c - '0')
			i += 1
		}

		for i < n && (data[i] == '\n' || data[i] == '\r') {
			i += 1
		}

		instrs[count] = is_left ? -val : val
		count += 1
	}
	return instrs, count
}

main :: proc() {
	data, ok := os.read_entire_file("input.txt")
	if !ok {
		fmt.eprintln("failed to read input.txt")
		return
	}
	defer delete(data)

	instrs, count := preparse(data)
	defer delete(instrs)

	p1, p2 := solve(raw_data(instrs), count)
	fmt.printf("Part 1: %d\nPart 2: %d\n", p1, p2)
}
