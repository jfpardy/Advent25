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
buffer:     .skip 20480
numbuf:     .skip 24

.text

_main:
    // Open and read input file
    adrp    x0, filename@PAGE
    add     x0, x0, filename@PAGEOFF
    mov     x1, #0
    syscall 0x2000005
    mov     x19, x0

    adrp    x1, buffer@PAGE
    add     x1, x1, buffer@PAGEOFF
    mov     x2, #20480
    syscall 0x2000003
    mov     x20, x0

    mov     x0, x19
    syscall 0x2000006

    // Initialize state
    mov     x21, #50            // pos
    mov     x22, #0             // cnt1 (part 1)
    mov     x23, #0             // cnt2 (part 2)
    adrp    x24, buffer@PAGE
    add     x24, x24, buffer@PAGEOFF
    add     x25, x24, x20       // end of buffer

next_line:
    cmp     x24, x25
    b.ge    print_results

    // Parse direction: is_left in w26
    ldrb    w0, [x24], #1
    cmp     w0, #'L'
    cset    w26, eq

    // Parse number into x27
    mov     x27, #0
parse_digit:
    cmp     x24, x25
    b.ge    apply_move
    ldrb    w0, [x24]
    sub     w1, w0, #'0'
    cmp     w1, #9
    b.hi    skip_newline
    mov     x2, #10
    mul     x27, x27, x2
    add     x27, x27, x1
    add     x24, x24, #1
    b       parse_digit

skip_newline:
    add     x24, x24, #1

apply_move:
    cbz     x27, next_line
    cbz     w26, move_right

// Moving left by x27 steps from position x21
move_left:
    // Count zeros: if pos == 0, cnt2 += d/100
    //              elif d >= pos, cnt2 += (d-pos)/100 + 1
    cbnz    x21, left_nonzero_pos

    // pos == 0: cnt2 += d / 100
    mov     x10, #100
    udiv    x9, x27, x10
    add     x23, x23, x9
    b       left_update_pos

left_nonzero_pos:
    // d >= pos?
    cmp     x27, x21
    b.lt    left_update_pos

    // cnt2 += (d - pos) / 100 + 1
    sub     x9, x27, x21
    mov     x10, #100
    udiv    x9, x9, x10
    add     x9, x9, #1
    add     x23, x23, x9

left_update_pos:
    // pos = (pos - d) % 100, handling negative
    sub     x21, x21, x27
    mov     x10, #100
    sdiv    x9, x21, x10
    msub    x21, x9, x10, x21
    cmp     x21, #0
    b.ge    check_part1
    add     x21, x21, x10
    b       check_part1

// Moving right by x27 steps from position x21
move_right:
    // cnt2 += (pos + d) / 100
    add     x9, x21, x27
    mov     x10, #100
    udiv    x9, x9, x10
    add     x23, x23, x9

    // pos = (pos + d) % 100
    add     x21, x21, x27
    mov     x10, #100
    udiv    x9, x21, x10
    msub    x21, x9, x10, x21

check_part1:
    // cnt1 += (pos == 0)
    cmp     x21, #0
    cinc    x22, x22, eq
    b       next_line

print_results:
    adrp    x0, p1_msg@PAGE
    add     x0, x0, p1_msg@PAGEOFF
    bl      print_str
    mov     x0, x22
    bl      print_num
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    bl      print_str

    adrp    x0, p2_msg@PAGE
    add     x0, x0, p2_msg@PAGEOFF
    bl      print_str
    mov     x0, x23
    bl      print_num
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    bl      print_str

    mov     x0, #0
    syscall 0x2000001

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
