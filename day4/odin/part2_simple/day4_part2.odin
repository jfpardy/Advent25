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

count_neighbors :: proc(grid: ^Grid, row, col: int) -> int {
	count := 0
	w := grid.width
	h := grid.height

	for offset in OFFSETS {
		nr := row + offset[0]
		nc := col + offset[1]
		if nr >= 0 && nr < h && nc >= 0 && nc < w {
			if grid.data[nr * w + nc] == '@' {
				count += 1
			}
		}
	}
	return count
}

is_accessible :: proc(grid: ^Grid, row, col: int) -> bool {
	idx := row * grid.width + col
	if grid.data[idx] != '@' do return false
	return count_neighbors(grid, row, col) < 4
}

remove_accessible :: proc(grid: ^Grid) -> int {
	accessible := make([dynamic][2]int)
	defer delete(accessible)

	// Find all accessible cells
	for row in 0 ..< grid.height {
		for col in 0 ..< grid.width {
			if is_accessible(grid, row, col) {
				append(&accessible, [2]int{row, col})
			}
		}
	}

	// Remove them
	for pos in accessible {
		grid.data[pos[0] * grid.width + pos[1]] = '.'
	}

	return len(accessible)
}

solve :: proc(grid: ^Grid) -> int {
	total := 0

	for {
		removed := remove_accessible(grid)
		if removed == 0 do break
		total += removed
	}

	return total
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

	for i in 0 ..< len(data) {
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

	result := solve(&grid)
	fmt.printf("Part 2: %d\n", result)
}
