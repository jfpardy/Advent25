package main

import "core:fmt"
import "core:os"

Grid :: struct {
	data:   []u8,
	width:  int,
	height: int,
}

OFFSETS :: [8][2]int{
	{-1, -1}, {-1, 0}, {-1, 1},
	{ 0, -1},          { 0, 1},
	{ 1, -1}, { 1, 0}, { 1, 1},
}

count_neighbors :: #force_inline proc "contextless" (grid: ^Grid, row, col: int) -> int {
	count := 0
	w := grid.width
	h := grid.height
	data := raw_data(grid.data)

	#no_bounds_check for offset in OFFSETS {
		nr := row + offset[0]
		nc := col + offset[1]
		if nr >= 0 && nr < h && nc >= 0 && nc < w {
			if data[nr * w + nc] == '@' {
				count += 1
			}
		}
	}
	return count
}

is_accessible :: #force_inline proc "contextless" (grid: ^Grid, row, col: int) -> bool {
	idx := row * grid.width + col
	if grid.data[idx] != '@' do return false
	return count_neighbors(grid, row, col) < 4
}

solve_single :: proc "contextless" (grid: ^Grid) -> int {
	count := 0
	w := grid.width
	h := grid.height

	#no_bounds_check for row in 0 ..< h {
		for col in 0 ..< w {
			if is_accessible(grid, row, col) {
				count += 1
			}
		}
	}
	return count
}

parse_grid :: proc(data: []u8) -> Grid {
	width := 0
	for i in 0 ..< len(data) {
		if data[i] == '\n' || data[i] == '\r' {
			width = i
			break
		}
	}

	cell_count := 0
	for c in data {
		if c == '@' || c == '.' {
			cell_count += 1
		}
	}

	height := cell_count / width
	grid_data := make([]u8, cell_count)
	dst_idx := 0

	#no_bounds_check for i in 0 ..< len(data) {
		c := data[i]
		if c == '@' || c == '.' {
			grid_data[dst_idx] = c
			dst_idx += 1
		}
	}

	return Grid{
		data   = grid_data,
		width  = width,
		height = height,
	}
}

main :: proc() {
	data, ok := os.read_entire_file("input.txt")
	if !ok {
		fmt.eprintln("failed to read input.txt")
		return
	}
	defer delete(data)

	grid := parse_grid(data)
	defer delete(grid.data)

	result := solve_single(&grid)
	fmt.printf("Part 1: %d\n", result)
}
