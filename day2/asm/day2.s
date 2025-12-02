.global _main
.align 4

.macro syscall n
    movz    x16, #(\n & 0xFFFF)
    movk    x16, #((\n >> 16) & 0xFFFF), lsl #16
    svc     #0x80
.endm

.data
filename:   .asciz "input.txt"
p1_msg:     .asciz "Part 1: "
p2_msg:     .asciz "Part 2: "
newline:    .asciz "\n"

.bss
buffer:     .skip 8192
numbuf:     .skip 24
invalid_ids: .skip 800000       // 100000 * 8 bytes
invalid_cnt: .skip 8            // count of invalid IDs
pow10_tbl:  .skip 160           // 20 * 8 bytes for powers of 10

.text

_main:
    stp     x29, x30, [sp, #-16]!
    mov     x29, sp

    // Initialize invalid_cnt to 0
    adrp    x0, invalid_cnt@PAGE
    add     x0, x0, invalid_cnt@PAGEOFF
    str     xzr, [x0]

    // Build power of 10 table
    bl      build_pow10

    // Open input file
    adrp    x0, filename@PAGE
    add     x0, x0, filename@PAGEOFF
    mov     x1, #0
    syscall 0x2000005
    mov     x19, x0             // fd

    // Read file
    adrp    x1, buffer@PAGE
    add     x1, x1, buffer@PAGEOFF
    mov     x2, #8192
    syscall 0x2000003
    mov     x20, x0             // bytes read

    // Close file
    mov     x0, x19
    syscall 0x2000006

    // Initialize
    mov     x21, #0             // part1_total
    adrp    x23, buffer@PAGE
    add     x23, x23, buffer@PAGEOFF  // current position in buffer
    add     x24, x23, x20       // end of buffer

parse_loop:
    cmp     x23, x24
    b.ge    compute_part2

    // Skip whitespace/newlines
    ldrb    w0, [x23]
    cmp     w0, #'\n'
    b.eq    skip_ws
    cmp     w0, #' '
    b.eq    skip_ws
    cmp     w0, #','
    b.eq    skip_ws
    b       parse_range
skip_ws:
    add     x23, x23, #1
    b       parse_loop

parse_range:
    // Parse low number
    mov     x25, #0             // low
parse_low:
    cmp     x23, x24
    b.ge    got_range
    ldrb    w0, [x23]
    cmp     w0, #'-'
    b.eq    got_low
    sub     w1, w0, #'0'
    cmp     w1, #9
    b.hi    got_range
    mov     x2, #10
    mul     x25, x25, x2
    add     x25, x25, x1
    add     x23, x23, #1
    b       parse_low

got_low:
    add     x23, x23, #1        // skip '-'

    // Parse high number
    mov     x26, #0             // high
parse_high:
    cmp     x23, x24
    b.ge    got_range
    ldrb    w0, [x23]
    sub     w1, w0, #'0'
    cmp     w1, #9
    b.hi    got_range
    mov     x2, #10
    mul     x26, x26, x2
    add     x26, x26, x1
    add     x23, x23, #1
    b       parse_high

got_range:
    // Skip comma if present
    cmp     x23, x24
    b.ge    process_range
    ldrb    w0, [x23]
    cmp     w0, #','
    b.ne    process_range
    add     x23, x23, #1

process_range:
    // x25 = low, x26 = high
    cbz     x26, parse_loop     // skip if high is 0

    // Part 1: sum doubled numbers in range
    mov     x0, x25
    mov     x1, x26
    bl      part1_range
    add     x21, x21, x0

    // Part 2: collect unique repeated-pattern numbers
    mov     x0, x25
    mov     x1, x26
    bl      part2_range

    b       parse_loop

compute_part2:
    // Sum all unique invalid IDs
    mov     x27, #0             // part2_total
    adrp    x0, invalid_ids@PAGE
    add     x0, x0, invalid_ids@PAGEOFF
    adrp    x1, invalid_cnt@PAGE
    add     x1, x1, invalid_cnt@PAGEOFF
    ldr     x3, [x1]            // count
    mov     x1, #0              // index
sum_invalid:
    cmp     x1, x3
    b.ge    print_results
    ldr     x2, [x0, x1, lsl #3]
    add     x27, x27, x2
    add     x1, x1, #1
    b       sum_invalid

print_results:
    adrp    x0, p1_msg@PAGE
    add     x0, x0, p1_msg@PAGEOFF
    bl      print_str
    mov     x0, x21
    bl      print_num
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    bl      print_str

    adrp    x0, p2_msg@PAGE
    add     x0, x0, p2_msg@PAGEOFF
    bl      print_str
    mov     x0, x27
    bl      print_num
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    bl      print_str

    mov     x0, #0
    ldp     x29, x30, [sp], #16
    syscall 0x2000001

// Build power of 10 table (pow10_tbl[i] = 10^i for i=0..19)
build_pow10:
    adrp    x0, pow10_tbl@PAGE
    add     x0, x0, pow10_tbl@PAGEOFF
    mov     x1, #1
    mov     x2, #0
    mov     x3, #10
build_pow10_loop:
    str     x1, [x0, x2, lsl #3]
    mul     x1, x1, x3
    add     x2, x2, #1
    cmp     x2, #20
    b.lt    build_pow10_loop
    ret

// Get 10^x0, result in x0
power10:
    adrp    x1, pow10_tbl@PAGE
    add     x1, x1, pow10_tbl@PAGEOFF
    ldr     x0, [x1, x0, lsl #3]
    ret

// Count digits in x0, result in x0
num_digits:
    cbz     x0, num_digits_one
    adrp    x1, pow10_tbl@PAGE
    add     x1, x1, pow10_tbl@PAGEOFF
    mov     x2, #1              // digit count
num_digits_loop:
    ldr     x3, [x1, x2, lsl #3]
    cmp     x0, x3
    b.lt    num_digits_done
    add     x2, x2, #1
    cmp     x2, #20
    b.lt    num_digits_loop
num_digits_done:
    mov     x0, x2
    ret
num_digits_one:
    mov     x0, #1
    ret

// Ceiling division: x0 = ceil(x0 / x1)
ceil_div:
    udiv    x2, x0, x1
    msub    x3, x2, x1, x0
    cbz     x3, ceil_div_done
    add     x2, x2, #1
ceil_div_done:
    mov     x0, x2
    ret

// Part 1: sum doubled numbers in range [x0, x1]
// Returns sum in x0
part1_range:
    stp     x29, x30, [sp, #-80]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]

    mov     x19, x0             // low
    mov     x20, x1             // high
    mov     x21, #0             // total
    mov     x22, #1             // k (digit count of base)

p1_k_loop:
    // multiplier = 10^k + 1
    mov     x0, x22
    bl      power10
    add     x23, x0, #1         // multiplier

    // min_doubled = (k > 1 ? 10^(k-1) : 1) * multiplier
    cmp     x22, #1
    b.eq    p1_min_base_one
    sub     x0, x22, #1
    bl      power10
    b       p1_calc_min_doubled
p1_min_base_one:
    mov     x0, #1
p1_calc_min_doubled:
    mul     x24, x0, x23        // min_doubled

    // if min_doubled > high, break
    cmp     x24, x20
    b.gt    p1_done

    // min_base = ceil(low / multiplier)
    mov     x0, x19
    mov     x1, x23
    bl      ceil_div
    mov     x24, x0             // min_base

    // max_base = high / multiplier
    udiv    x25, x20, x23       // max_base

    // base_min = (k > 1) ? 10^(k-1) : 1
    cmp     x22, #1
    b.eq    p1_base_min_one
    sub     x0, x22, #1
    bl      power10
    mov     x26, x0
    b       p1_got_base_min
p1_base_min_one:
    mov     x26, #1
p1_got_base_min:

    // base_max = 10^k - 1
    mov     x0, x22
    bl      power10
    sub     x27, x0, #1         // base_max

    // Clamp: if min_base < base_min, min_base = base_min
    cmp     x24, x26
    csel    x24, x26, x24, lt

    // Clamp: if max_base > base_max, max_base = base_max
    cmp     x25, x27
    csel    x25, x27, x25, gt

    // if min_base <= max_base
    cmp     x24, x25
    b.gt    p1_next_k

    // count = max_base - min_base + 1
    sub     x0, x25, x24
    add     x0, x0, #1          // count

    // base_sum = (min_base + max_base) * count / 2
    add     x1, x24, x25
    mul     x1, x1, x0
    lsr     x1, x1, #1          // base_sum

    // total += base_sum * multiplier
    mul     x1, x1, x23
    add     x21, x21, x1

p1_next_k:
    add     x22, x22, #1
    cmp     x22, #11            // max 11 digits for bases (22 digit doubled numbers)
    b.lt    p1_k_loop

p1_done:
    mov     x0, x21
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #80
    ret

// Add x0 to invalid_ids if unique (uses memory for count)
add_if_unique:
    stp     x29, x30, [sp, #-48]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]

    mov     x19, x0             // value to add

    // Get current count
    adrp    x20, invalid_cnt@PAGE
    add     x20, x20, invalid_cnt@PAGEOFF
    ldr     x21, [x20]          // count

    // Get array base
    adrp    x22, invalid_ids@PAGE
    add     x22, x22, invalid_ids@PAGEOFF

    mov     x2, #0
add_unique_check:
    cmp     x2, x21
    b.ge    add_unique_new
    ldr     x3, [x22, x2, lsl #3]
    cmp     x3, x19
    b.eq    add_unique_done     // already exists
    add     x2, x2, #1
    b       add_unique_check

add_unique_new:
    // Check capacity
    movz    x0, #0x86A0         // 100000 = 0x186A0
    movk    x0, #0x1, lsl #16
    cmp     x21, x0
    b.ge    add_unique_done     // array full

    // Add to array
    str     x19, [x22, x21, lsl #3]
    add     x21, x21, #1
    str     x21, [x20]          // update count

add_unique_done:
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #48
    ret

// Part 2: collect unique repeated-pattern numbers in range [x0, x1]
part2_range:
    stp     x29, x30, [sp, #-96]!
    mov     x29, sp
    stp     x19, x20, [sp, #16]
    stp     x21, x22, [sp, #32]
    stp     x23, x24, [sp, #48]
    stp     x25, x26, [sp, #64]
    stp     x27, x28, [sp, #80]

    mov     x19, x0             // low
    mov     x20, x1             // high

    // Get max_digits of high
    mov     x0, x20
    bl      num_digits
    mov     x21, x0             // max_digits

    mov     x23, #1             // d (base digit count)

p2_d_loop:
    cmp     x23, x21
    b.gt    p2_done

    mov     x24, #2             // k (repetition count)

p2_k_loop:
    // total_digits = d * k
    mul     x25, x23, x24
    cmp     x25, x21
    b.gt    p2_next_d

    // multiplier = (10^(d*k) - 1) / (10^d - 1)
    mov     x0, x25
    bl      power10
    sub     x26, x0, #1         // 10^(d*k) - 1

    mov     x0, x23
    bl      power10
    sub     x27, x0, #1         // 10^d - 1

    udiv    x26, x26, x27       // multiplier

    // base_min = (d > 1) ? 10^(d-1) : 1
    cmp     x23, #1
    b.eq    p2_base_min_one
    sub     x0, x23, #1
    bl      power10
    mov     x27, x0
    b       p2_got_base_min
p2_base_min_one:
    mov     x27, #1
p2_got_base_min:

    // base_max = 10^d - 1
    mov     x0, x23
    bl      power10
    sub     x28, x0, #1         // base_max

    // min_base = ceil(low / multiplier)
    mov     x0, x19
    mov     x1, x26
    bl      ceil_div
    // Clamp: if min_base < base_min, min_base = base_min
    cmp     x0, x27
    csel    x0, x27, x0, lt
    // Save min_base to stack (16-byte aligned)
    stp     x0, xzr, [sp, #-16]!

    // max_base = high / multiplier
    udiv    x0, x20, x26        // max_base
    // Clamp: if max_base > base_max, max_base = base_max
    cmp     x0, x28
    csel    x1, x28, x0, gt     // max_base in x1

    // Restore min_base
    ldp     x0, x2, [sp], #16   // min_base in x0

    // Iterate bases from min_base to max_base
    cmp     x0, x1
    b.gt    p2_next_k

p2_base_loop:
    // val = base * multiplier
    mul     x2, x0, x26
    // Save registers before call
    stp     x0, x1, [sp, #-16]!
    mov     x0, x2
    bl      add_if_unique
    ldp     x0, x1, [sp], #16

    add     x0, x0, #1
    cmp     x0, x1
    b.le    p2_base_loop

p2_next_k:
    add     x24, x24, #1
    b       p2_k_loop

p2_next_d:
    add     x23, x23, #1
    b       p2_d_loop

p2_done:
    ldp     x27, x28, [sp, #80]
    ldp     x25, x26, [sp, #64]
    ldp     x23, x24, [sp, #48]
    ldp     x21, x22, [sp, #32]
    ldp     x19, x20, [sp, #16]
    ldp     x29, x30, [sp], #96
    ret

// Print null-terminated string at x0
print_str:
    mov     x9, x0
    mov     x2, #0
print_str_len:
    ldrb    w3, [x0, x2]
    cbz     w3, print_str_write
    add     x2, x2, #1
    b       print_str_len
print_str_write:
    mov     x0, #1
    mov     x1, x9
    syscall 0x2000004
    ret

// Print integer at x0
print_num:
    adrp    x1, numbuf@PAGE
    add     x1, x1, numbuf@PAGEOFF
    add     x1, x1, #20
    mov     x2, x1
    mov     x3, #10
    cbnz    x0, print_num_loop
    sub     x1, x1, #1
    mov     w4, #'0'
    strb    w4, [x1]
    b       print_num_write
print_num_loop:
    cbz     x0, print_num_write
    udiv    x4, x0, x3
    msub    x5, x4, x3, x0
    add     w5, w5, #'0'
    sub     x1, x1, #1
    strb    w5, [x1]
    mov     x0, x4
    b       print_num_loop
print_num_write:
    sub     x2, x2, x1
    mov     x0, #1
    syscall 0x2000004
    ret
