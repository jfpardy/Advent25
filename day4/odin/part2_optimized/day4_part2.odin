package main

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:thread"

// Grid dimensions (compile-time constants for max performance)
GRID_WIDTH  :: 139
GRID_HEIGHT :: 139
ROW_U64S    :: 3  // ceil(139/64) = 3
MAX_CELLS   :: GRID_WIDTH * GRID_HEIGHT

NUM_THREADS :: 4
ROWS_PER_THREAD :: (GRID_HEIGHT + NUM_THREADS - 1) / NUM_THREADS
MAX_PER_THREAD :: ROWS_PER_THREAD * GRID_WIDTH

// Bit-packed grid: 1 = roll, 0 = empty
Bit_Grid :: struct {
	rows: [GRID_HEIGHT][ROW_U64S]u64,
}

// Dirty flags - cells to check next iteration
Dirty_Set :: struct {
	flags: [GRID_HEIGHT][ROW_U64S]u64,
}

// Thread work chunk
Work_Chunk :: struct {
	grid:      ^Bit_Grid,
	dirty:     ^Dirty_Set,
	start_row: int,
	end_row:   int,
	results:   ^[MAX_PER_THREAD][2]i16,
	count:     ^int,
}

// Inline bit operations
get_bit :: #force_inline proc "contextless" (grid: ^Bit_Grid, r, c: int) -> bool {
	return (grid.rows[r][c / 64] >> u64(c % 64)) & 1 == 1
}

clear_bit :: #force_inline proc "contextless" (grid: ^Bit_Grid, r, c: int) {
	grid.rows[r][c / 64] &~= 1 << u64(c % 64)
}

set_dirty :: #force_inline proc "contextless" (dirty: ^Dirty_Set, r, c: int) {
	dirty.flags[r][c / 64] |= 1 << u64(c % 64)
}

is_dirty :: #force_inline proc "contextless" (dirty: ^Dirty_Set, r, c: int) -> bool {
	return (dirty.flags[r][c / 64] >> u64(c % 64)) & 1 == 1
}

count_neighbors :: #force_inline proc "contextless" (grid: ^Bit_Grid, r, c: int) -> int {
	count := 0

	// Unrolled neighbor checks with bounds
	#no_bounds_check {
		// Row above
		if r > 0 {
			if c > 0 && get_bit(grid, r-1, c-1) do count += 1
			if get_bit(grid, r-1, c) do count += 1
			if c < GRID_WIDTH-1 && get_bit(grid, r-1, c+1) do count += 1
		}

		// Same row
		if c > 0 && get_bit(grid, r, c-1) do count += 1
		if c < GRID_WIDTH-1 && get_bit(grid, r, c+1) do count += 1

		// Row below
		if r < GRID_HEIGHT-1 {
			if c > 0 && get_bit(grid, r+1, c-1) do count += 1
			if get_bit(grid, r+1, c) do count += 1
			if c < GRID_WIDTH-1 && get_bit(grid, r+1, c+1) do count += 1
		}
	}

	return count
}

is_accessible :: #force_inline proc "contextless" (grid: ^Bit_Grid, r, c: int) -> bool {
	if !get_bit(grid, r, c) do return false
	return count_neighbors(grid, r, c) < 4
}

mark_neighbors_dirty :: #force_inline proc "contextless" (dirty: ^Dirty_Set, r, c: int) {
	// Mark all 9 cells in 3x3 neighborhood (including self for simplicity)
	#no_bounds_check {
		for dr in -1 ..= 1 {
			nr := r + dr
			if nr >= 0 && nr < GRID_HEIGHT {
				for dc in -1 ..= 1 {
					nc := c + dc
					if nc >= 0 && nc < GRID_WIDTH {
						set_dirty(dirty, nr, nc)
					}
				}
			}
		}
	}
}

// Worker thread for finding accessible cells
worker_find :: proc(task: thread.Task) {
	chunk := cast(^Work_Chunk)task.data
	grid := chunk.grid
	dirty := chunk.dirty
	local_count := 0

	#no_bounds_check for r in chunk.start_row ..< chunk.end_row {
		for u in 0 ..< ROW_U64S {
			// Only check cells that are both dirty AND have a roll
			bits := dirty.flags[r][u] & grid.rows[r][u]

			for bits != 0 {
				// Get position of lowest set bit
				bit_pos := intrinsics.count_trailing_zeros(bits)
				col := u * 64 + int(bit_pos)

				if col < GRID_WIDTH && is_accessible(grid, r, col) {
					chunk.results[local_count] = {i16(r), i16(col)}
					local_count += 1
				}

				// Clear lowest bit
				bits &= bits - 1
			}
		}
	}

	chunk.count^ = local_count
}

solve_optimized :: proc(grid: ^Bit_Grid) -> int {
	dirty: Dirty_Set

	// Initially, all cells with rolls are dirty
	#no_bounds_check for r in 0 ..< GRID_HEIGHT {
		for u in 0 ..< ROW_U64S {
			dirty.flags[r][u] = grid.rows[r][u]
		}
	}

	// Thread pool setup
	pool: thread.Pool
	thread.pool_init(&pool, context.allocator, NUM_THREADS)
	defer thread.pool_destroy(&pool)

	// Per-thread result buffers (fixed size, no allocation in loop)
	thread_results: [NUM_THREADS][MAX_PER_THREAD][2]i16
	thread_counts: [NUM_THREADS]int
	chunks: [NUM_THREADS]Work_Chunk

	// Initialize chunks
	for i in 0 ..< NUM_THREADS {
		start_row := i * ROWS_PER_THREAD
		end_row := min((i + 1) * ROWS_PER_THREAD, GRID_HEIGHT)

		chunks[i] = Work_Chunk{
			grid      = grid,
			dirty     = &dirty,
			start_row = start_row,
			end_row   = end_row,
			results   = &thread_results[i],
			count     = &thread_counts[i],
		}
	}

	total := 0

	for {
		// Reset counts
		for i in 0 ..< NUM_THREADS {
			thread_counts[i] = 0
		}

		// Parallel find phase
		for i in 0 ..< NUM_THREADS {
			if chunks[i].start_row < GRID_HEIGHT {
				thread.pool_add_task(&pool, context.allocator, worker_find, &chunks[i])
			}
		}
		thread.pool_start(&pool)
		thread.pool_finish(&pool)

		// Count total found
		total_found := 0
		for i in 0 ..< NUM_THREADS {
			total_found += thread_counts[i]
		}

		if total_found == 0 do break

		// Clear dirty flags
		#no_bounds_check for r in 0 ..< GRID_HEIGHT {
			for u in 0 ..< ROW_U64S {
				dirty.flags[r][u] = 0
			}
		}

		// Sequential remove and mark neighbors dirty
		#no_bounds_check for i in 0 ..< NUM_THREADS {
			for j in 0 ..< thread_counts[i] {
				r := int(thread_results[i][j][0])
				c := int(thread_results[i][j][1])
				clear_bit(grid, r, c)
				mark_neighbors_dirty(&dirty, r, c)
			}
		}

		total += total_found
	}

	return total
}

parse_grid :: proc(data: []u8) -> Bit_Grid {
	grid: Bit_Grid

	row := 0
	col := 0

	#no_bounds_check for i in 0 ..< len(data) {
		c := data[i]
		if c == '@' {
			grid.rows[row][col / 64] |= 1 << u64(col % 64)
			col += 1
		} else if c == '.' {
			col += 1
		} else if c == '\n' {
			row += 1
			col = 0
		}
		// Skip \r
	}

	return grid
}

main :: proc() {
	data, ok := os.read_entire_file("input.txt")
	if !ok {
		fmt.eprintln("failed to read input.txt")
		return
	}
	defer delete(data)

	grid := parse_grid(data)
	result := solve_optimized(&grid)
	fmt.printf("Part 2: %d\n", result)
}
