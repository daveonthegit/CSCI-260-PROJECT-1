#IVERSON
.data # Start of data segment (static/predefined data)
# DONOTMODIFYTHISLINE
frameBuffer: .space 0x80000     # $s0 <- base address for 512x256 pixels, 4 bytes per pixel
M: .word 100                    # $s1 <- outer size of L-shape (width/height)
N: .word 60                     # $s2 <- inner square size (used to calculate thickness)
cr: .word 0                     # $s3 <- red component for arrowhead color (0-255)
cg: .word 63                    # $s4 <- green component for arrowhead color (0-255)
cb: .word 0                     # $s5 <- blue component for arrowhead color (0-255)
# DONOTMODIFYTHISLINE
# Your other variables go BELOW here only

.text                           # Start of code segment
.globl main                     # Declare main as global for startup
main:                           # Program entry point
    addi $sp, $sp, -20          # $sp <- allocate 20 bytes on stack 
                                # 0($sp): bar color
                                # 4($sp): arrowhead color
                                # 8($sp): temporary storage
                                # 12($sp): start column ($s6 equivalent)
                                # 16($sp): start row ($s7 equivalent)

    la   $s0, frameBuffer       # $s0 <- base address of framebuffer for pixel drawing

    la   $t9, M                 # $t9 <- base address of M block (contains multiple parameters)
    lw   $s1, 0($t9)            # $s1 <- M (outer size)
    lw   $s2, 4($t9)            # $s2 <- N (inner size)
    lw   $s3, 8($t9)            # $s3 <- cr (red color component)
    lw   $s4, 12($t9)           # $s4 <- cg (green color component)
    lw   $s5, 16($t9)           # $s5 <- cb (blue color component)

    li   $t9, 1                 # $t9 <- 1 (can_draw flag, assume drawing is possible)

    addi   $t1, $zero, 512     # Load display width
    addi   $t2,$zero, 256    # Load display height


    slt  $t3, $s2, $s1          # $t3 <- 1 if N < M
    beq  $t3, $zero, cant_draw  # If N >= M, cannot draw (jump to cant_draw)

    sub  $t0, $s1, $s2          # $t0 <- thickness = M - N

    li   $t3, 16                # $t3 <- constant 16 (padding/margin)
    sra  $t4, $t0, 1            # $t4 <- thickness / 2
    add  $t5, $t3, $t4          # $t5 <- 16 + (thickness/2)
    add  $t6, $s2, $t5          # $t6 <- total width required
    slt  $t7, $t1, $t6          # $t7 <- 1 if screen width is less than required width
    bne  $t7, $zero, cant_draw  # If true, cannot draw

    li   $t3, 8                # $t3 <- constant 8 
    add  $t6, $s1, $t3          # $t6 <- total height required
    slt  $t7, $t2, $t6          # $t7 <- 1 if screen height is less than required height
    bne  $t7, $zero, cant_draw  # If true, cannot draw

    # Remove the odd number checks as they were preventing valid shapes
    
    sra  $t4, $t0, 1            # $t4 <- thickness / 2
    addi  $t3, $s1, 8           # $t3 <- M + 8
    add  $t3, $t4, $t3          # $t3 <- M+8+thickness/2 = total length
    sub  $t5, $t1, $t3          # $t5 <- horizontal centering offset
    sra  $t6, $t5, 1            # $t6 <- start column by dividing offset by 2
    sw   $t6, 12($sp)           # Store start column on stack (replacing $s6)
    addi $t3, $s1, 4		# $t6 <- Add 1/2 Overhang to height ($s1 (M) + 4)
    sub  $t5, $t2, $t3          # $t5 <- vertical centering offset
    sra  $t6, $t5, 1            # $t6 <- start row by dividing offset by 2
    sw   $t6, 16($sp)           # Store start row on stack (replacing $s7)

    j build_colors              # Jump to color computation section

cant_draw:                      # Label for drawing not possible
    li $t9, 0                   # $t9 <- 0 (set can_draw flag to 0)

build_colors:                   # Color computation section
    sll  $t4, $s3, 16           # $t4 <- red component shifted left by 16 bits
    sll  $t5, $s4, 8            # $t5 <- green component shifted left by 8 bits
    or   $t6, $t4, $t5          # $t6 <- combined red and green components
    or   $t6, $t6, $s5          # $t6 <- add blue component to form full color
    sw   $t6, 4($sp)            # Save arrowhead color on stack

    li   $t7, 255               # $t7 <- maximum color value
    sll  $t4, $s3, 2            # $t4 <- red * 4 for scaling
    slt  $t8, $t7, $t4          # $t8 <- 1 if scaled red exceeds 255
    beq  $t8, $zero, ok_r       # If not, skip clamping
    li   $t4, 255               # $t4 <- clamp red to 255
ok_r: sll $t4, $t4, 16          # $t4 <- shift red to correct color position

    sll  $t5, $s4, 2            # $t5 <- green * 4 for scaling
    slt  $t8, $t7, $t5          # $t8 <- 1 if scaled green exceeds 255
    beq  $t8, $zero, ok_g       # If not, skip clamping
    li   $t5, 255               # $t5 <- clamp green to 255
ok_g: sll $t5, $t5, 8           # $t5 <- shift green to correct color position

    sll  $t6, $s5, 2            # $t6 <- blue * 4 for scaling
    slt  $t8, $t7, $t6          # $t8 <- 1 if scaled blue exceeds 255
    beq  $t8, $zero, ok_b       # If not, skip clamping
    li   $t6, 255               # $t6 <- clamp blue to 255
ok_b:
    or   $t8, $t4, $t5          # $t8 <- combine red and green components
    or   $t8, $t8, $t6          # $t8 <- add blue component
    sw   $t8, 0($sp)            # Save bar color on stack

    li $t4, 0                   # $t4 <- row counter initialized to 0
fill_rows:
    li $t5, 0                   # $t5 <- column counter initialized to 0
fill_cols:
    li $t6, 0x00FFFF00          # $t6 <- yellow color (ARGB format)
    mul $t7, $t4, $t1           # $t7 <- pixel offset: row * width
    add $t7, $t7, $t5           # $t7 <- add column to pixel offset
    sll $t7, $t7, 2             # $t7 <- multiply by 4 to get byte offset
    add $t7, $t7, $s0           # $t7 <- add frame buffer base address
    sw  $t6, 0($t7)             # Write yellow pixel to frame buffer
    addi $t5, $t5, 1            # $t5 <- increment column
    slt $t3, $t5, $t1           # $t3 <- 1 if column < display width
    bne $t3, $zero, fill_cols   # If not done, continue filling columns
    addi $t4, $t4, 1            # $t4 <- increment row
    slt $t3, $t4, $t2           # $t3 <- 1 if row < display height
    bne $t3, $zero, fill_rows   # If not done, continue filling rows

    beq $t9, $zero, exit        # If can't draw (flag is 0), exit program
    j draw_shape                # Otherwise, jump to shape drawing routine

draw_shape:
    lw $t6, 0($sp)              # $t6 <- bar color from stack
    lw $t7, 4($sp)              # $t7 <- arrowhead color from stack
    lw $s6, 12($sp)             # Load start column from stack (replacing $s6)
    lw $s7, 16($sp)             # Load start row from stack (replacing $s7)

    li $t4, 0                   # $t4 <- row counter for vertical bar
vbar_row:
    li $t5, 0                   # $t5 <- column counter for vertical bar
vbar_col:
    add $t8, $s7, $t4           # $t8 <- current row
    add $t9, $s6, $t5           # $t9 <- current column
    mul $t3, $t8, $t1           # $t3 <- row * display width
    add $t3, $t3, $t9           # $t3 <- add column to get pixel offset
    sll $t3, $t3, 2             # $t3 <- multiply by 4 to get byte offset
    add $t3, $t3, $s0           # $t3 <- add frame buffer base address
    sw  $t6, 0($t3)             # Write bar color pixel
    addi $t5, $t5, 1            # $t5 <- increment column
    slt $t3, $t5, $t0           # $t3 <- 1 if column < bar thickness
    bne $t3, $zero, vbar_col    # If not done, continue filling vertical bar columns
    addi $t4, $t4, 1            # $t4 <- increment row
    slt $t3, $t4, $s1           # $t3 <- 1 if row < outer size
    bne $t3, $zero, vbar_row    # If not done, continue filling vertical bar rows

    li $t4, 0                   # $t4 <- row counter for horizontal bar
hbar_row:
    li $t5, 0                   # $t5 <- column counter for horizontal bar
hbar_col:
    add $t8, $s7, $s2           # $t8 <- starting row for horizontal bar
    add $t8, $t8, $t4           # $t8 <- add current row offset
    add $t9, $s6, $t5           # $t9 <- current column
    mul $t3, $t8, $t1           # $t3 <- row * display width
    add $t3, $t3, $t9           # $t3 <- add column to get pixel offset
    sll $t3, $t3, 2             # $t3 <- multiply by 4 to get byte offset
    add $t3, $t3, $s0           # $t3 <- add frame buffer base address
    sw  $t6, 0($t3)             # Write bar color pixel
    addi $t5, $t5, 1            # $t5 <- increment column
    slt $t3, $t5, $s1           # $t3 <- 1 if column < outer size
    bne $t3, $zero, hbar_col    # If not done, continue filling horizontal bar columns
    addi $t4, $t4, 1            # $t4 <- increment row
    slt $t3, $t4, $t0           # $t3 <- 1 if row < bar thickness
    bne $t3, $zero, hbar_row    # If not done, continue filling horizontal bar rows

    li $t4, 0                   # $t4 <- arrow drawing loop counter
arrow_loop:
    li $t5, 16                  # $t5 <- base offset for arrow
    add $t5, $t5, $t0           # $t5 <- add thickness to base offset
    sll $t6, $t4, 1             # $t6 <- multiply current counter by 2
    sub $t7, $t5, $t6           # $t7 <- calculate arrow width at this level
    slt $t8, $zero, $t7         # $t8 <- 1 if width is positive
    beq $t8, $zero, arrow_done  # If width is zero or negative, exit arrow loop

    li $t9, 8                   # $t9 <- constant 8
    sub $t9, $t9, $t4           # $t9 <- adjust vertical position
    add $t3, $s7, $s2           # $t3 <- add base row offset
    sub $t3, $t3, $t9           # $t3 <- adjust vertical position further

    li $t5, 0                   # $t5 <- row counter for arrow
arrow_row_loop:
    slt $t8, $t5, $t7           # $t8 <- 1 if current row is within arrow width
    beq $t8, $zero, arrow_next  # If not, move to next arrow level
    add $t6, $t3, $t5           # $t6 <- calculate current row
    add $t9, $s6, $s1           # $t9 <- add base column offset
    add $t9, $t9, $t4           # $t9 <- adjust column position
    mul $t8, $t6, $t1           # $t8 <- row * display width
    add $t8, $t8, $t9           # $t8 <- add column to get pixel offset
    sll $t8, $t8, 2             # $t8 <- multiply by 4 to get byte offset
    add $t8, $t8, $s0           # $t8 <- add frame buffer base address
    sw $t7, 8($sp)              # Temporarily store loop variable
    lw $t7, 4($sp)              # $t7 <- load arrowhead color
    sw $t7, 0($t8)              # Write arrowhead color pixel
    lw $t7, 8($sp)              # Restore loop variable
    addi $t5, $t5, 1            # $t5 <- increment row
    j arrow_row_loop            # Continue arrow row loop
arrow_next:
    addi $t4, $t4, 1            # $t4 <- increment arrow level
    j arrow_loop                # Continue arrow drawing loop
arrow_done:

exit:
    addi $sp, $sp, 20           # Restore stack pointer (changed from 12 to 20)
    li $v0, 10                  # $v0 <- system call code for program exit
    syscall                     # Exit program
