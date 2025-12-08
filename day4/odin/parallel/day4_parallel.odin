package main

import "core:fmt"
import "core:os"
import "core:thread"

Grid :: struct {
	data:   []u8,
	width:  int,
	height: int,
}

Work_Chunk :: struct {
	grid:      ^Grid,
	start_row: int,
	end_row:   int,
	result:    ^int,
}

OFFSETS :: [8][2]int{
	{-1, -1}, {-1, 0}, {-1, 1},
	{ 0, -1},          { 0, 1},
	{ 1, -1}, { 1, 0}, { 1, 1},
}

NUM_THREADS :: 4

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

worker_proc :: proc(task: thread.Task) {
	chunk := cast(^Work_Chunk)task.data
	local_count := 0
	grid := chunk.grid
	w := grid.width

	#no_bounds_check for row in chunk.start_row ..< chunk.end_row {
		for col in 0 ..< w {
			if is_accessible(grid, row, col) {
				local_count += 1
			}
		}
	}

	chunk.result^ = local_count
}

solve_parallel :: proc(grid: ^Grid) -> int {
	pool: thread.Pool
	thread.pool_init(&pool, context.allocator, NUM_THREADS)
	defer thread.pool_destroy(&pool)

	results: [NUM_THREADS]int
	chunks: [NUM_THREADS]Work_Chunk

	rows_per_thread := (grid.height + NUM_THREADS - 1) / NUM_THREADS

	actual_threads := 0
	for i in 0 ..< NUM_THREADS {
		start_row := i * rows_per_thread
		end_row := min((i + 1) * rows_per_thread, grid.height)

		if start_row >= grid.height do break

		chunks[i] = Work_Chunk{
			grid      = grid,
			start_row = start_row,
			end_row   = end_row,
			result    = &results[i],
		}

		thread.pool_add_task(&pool, context.allocator, worker_proc, &chunks[i])
		actual_threads += 1
	}

	thread.pool_start(&pool)
	thread.pool_finish(&pool)

	total := 0
	for i in 0 ..< actual_threads {
		total += results[i]
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

	result := solve_parallel(&grid)
	fmt.printf("Part 1: %d\n", result)
}
