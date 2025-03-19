.data
# DONOTMODIFYTHISLINE
frameBuffer: .space 0x80000 # 512 wide X 256 high pixels
M: .word 100
N: .word 76
cr: .word 0
cg: .word 63
cb: .word 0
# DONOTMODIFYTHISLINE
# Your other variables go BELOW here only
yellow: .word 0x00FFFF00     # Yellow color for background
arrowColor: .word 0          # Will store the arrow color
arrowHeadColor: .word 0      # Will store the arrowhead color
displayWidth: .word 512      # Width of the display
displayHeight: .word 256     # Height of the display
arrowHeadSize: .word 8       # Size of arrowhead (overhang)
arrowLength: .word 12        # Length of arrow shaft
totalWidth: .word 0          # Total width of the figure
totalHeight: .word 0         # Total height of the figure
startX: .word 0              # Starting X coordinate
startY: .word 0              # Starting Y coordinate

.text
main:
    # Calculate the arrow colors
    # First, calculate the arrowhead color from cr, cg, cb
    lw $t0, cr             # Load red component
    lw $t1, cg             # Load green component
    lw $t2, cb             # Load blue component
    
    # Create arrowhead color
    sll $t0, $t0, 16       # Shift red to bits 23:16
    sll $t1, $t1, 8        # Shift green to bits 15:8
    or $t3, $t0, $t1       # Combine red and green
    or $t3, $t3, $t2       # Add blue component
    sw $t3, arrowHeadColor # Store arrowhead color
    
    # Calculate arrow color (4x each component)
    lw $t0, cr             # Load red component
    lw $t1, cg             # Load green component
    lw $t2, cb             # Load blue component
    
    sll $t0, $t0, 2        # Multiply red by 4
    sll $t1, $t1, 2        # Multiply green by 4
    sll $t2, $t2, 2        # Multiply blue by 4
    
    # Check for overflow in each component
    li $t3, 255            # Maximum value for any component
    blt $t0, $t3, redOK    # If red <= 255, it's OK
    move $t0, $t3          # Otherwise, set to max
redOK:
    blt $t1, $t3, greenOK  # If green <= 255, it's OK
    move $t1, $t3          # Otherwise, set to max
greenOK:
    blt $t2, $t3, blueOK   # If blue <= 255, it's OK
    move $t2, $t3          # Otherwise, set to max
blueOK:
    
    # Create arrow color
    sll $t0, $t0, 16       # Shift red to bits 23:16
    sll $t1, $t1, 8        # Shift green to bits 15:8
    or $t3, $t0, $t1       # Combine red and green
    or $t3, $t3, $t2       # Add blue component
    sw $t3, arrowColor     # Store arrow color
    
    # Calculate total dimensions
    lw $t0, M              # Load M
    lw $t1, N              # Load N
    lw $t2, arrowHeadSize  # Load arrowhead size
    lw $t3, arrowLength    # Load arrow length
    
    # Total width = M + arrowLength + arrowHeadSize
    add $t4, $t0, $t3      # M + arrowLength
    add $t4, $t4, $t2      # M + arrowLength + arrowHeadSize
    sw $t4, totalWidth     # Store total width
    
    # Total height = N (for rectangle)
    move $t5, $t1          # N
    
    # Check if arrowhead height is larger than N
    sll $t6, $t2, 1        # arrowHeadSize * 2
    ble $t6, $t1, heightOK # If arrowheadHeight <= N, use N
    move $t5, $t6          # Otherwise, use arrowheadHeight
heightOK:
    sw $t5, totalHeight    # Store total height
    
    # Check if figure can be drawn
    lw $t0, totalWidth     # Load total width
    lw $t1, totalHeight    # Load total height
    lw $t2, displayWidth   # Load display width
    lw $t3, displayHeight  # Load display height
    
    # Check if figure fits in display
    bgt $t0, $t2, drawBackgroundOnly # If width too large, only draw background
    bgt $t1, $t3, drawBackgroundOnly # If height too large, only draw background
    
    # Check if figure can be centered exactly
    sub $t4, $t2, $t0      # displayWidth - totalWidth
    sub $t5, $t3, $t1      # displayHeight - totalHeight
    
    # Check if horizontal centering possible
    andi $t6, $t4, 1       # $t4 mod 2
    bne $t6, $zero, drawBackgroundOnly # If odd, we can't center exactly
    
    # Check if vertical centering possible
    andi $t6, $t5, 1       # $t5 mod 2
    bne $t6, $zero, drawBackgroundOnly # If odd, we can't center exactly
    
    # Calculate starting coordinates
    srl $t4, $t4, 1        # (displayWidth - totalWidth) / 2
    srl $t5, $t5, 1        # (displayHeight - totalHeight) / 2
    sw $t4, startX         # Store starting X
    sw $t5, startY         # Store starting Y
    
    # All checks passed, draw the figure
    j drawFigure
    
drawBackgroundOnly:
    # Draw only the background
    la $t0, frameBuffer    # $t0 = base address of frame buffer
    li $t1, 0              # $t1 = counter
    lw $t2, displayWidth   # $t2 = display width
    lw $t3, displayHeight  # $t3 = display height
    mul $t4, $t2, $t3      # $t4 = total number of pixels
    lw $t5, yellow         # $t5 = yellow color
    
backgroundLoop:
    sw $t5, 0($t0)         # Store yellow at current pixel
    addi $t0, $t0, 4       # Move to next pixel
    addi $t1, $t1, 1       # Increment counter
    blt $t1, $t4, backgroundLoop # Continue if not done
    
    # Exit program
    li $v0, 10             # Exit syscall
    syscall
    
drawFigure:
    # Draw the entire figure
    # First, draw the background
    la $t0, frameBuffer    # $t0 = base address of frame buffer
    li $t1, 0              # $t1 = counter
    lw $t2, displayWidth   # $t2 = display width
    lw $t3, displayHeight  # $t3 = display height
    mul $t4, $t2, $t3      # $t4 = total number of pixels
    lw $t5, yellow         # $t5 = yellow color
    
figureBackgroundLoop:
    sw $t5, 0($t0)         # Store yellow at current pixel
    addi $t0, $t0, 4       # Move to next pixel
    addi $t1, $t1, 1       # Increment counter
    blt $t1, $t4, figureBackgroundLoop # Continue if not done
    
    # Draw the rectangle
    lw $t0, startX         # $t0 = starting X
    lw $t1, startY         # $t1 = starting Y
    lw $t2, M              # $t2 = width (M)
    lw $t3, N              # $t3 = height (N)
    lw $t4, arrowColor     # $t4 = arrow color
    
    # Draw top horizontal line
    move $t5, $t0          # $t5 = current X
    move $t6, $t1          # $t6 = current Y
    
topLineLoop:
    # Calculate pixel address
    la $t7, frameBuffer    # $t7 = base address
    lw $t8, displayWidth   # $t8 = display width
    mul $t8, $t6, $t8      # $t8 = Y * display width
    add $t8, $t8, $t5      # $t8 = Y * display width + X
    sll $t8, $t8, 2        # $t8 = 4 * (Y * display width + X)
    add $t7, $t7, $t8      # $t7 = address of current pixel
    
    sw $t4, 0($t7)         # Store color at current pixel
    
    addi $t5, $t5, 1       # Increment X
    sub $t7, $t5, $t0      # $t7 = X - startX
    ble $t7, $t2, topLineLoop # Continue if not done
    
    # Draw right vertical line
    move $t5, $t0          # $t5 = startX
    add $t5, $t5, $t2      # $t5 = startX + M
    move $t6, $t1          # $t6 = startY
    
rightLineLoop:
    # Calculate pixel address
    la $t7, frameBuffer    # $t7 = base address
    lw $t8, displayWidth   # $t8 = display width
    mul $t8, $t6, $t8      # $t8 = Y * display width
    add $t8, $t8, $t5      # $t8 = Y * display width + X
    sll $t8, $t8, 2        # $t8 = 4 * (Y * display width + X)
    add $t7, $t7, $t8      # $t7 = address of current pixel
    
    sw $t4, 0($t7)         # Store color at current pixel
    
    addi $t6, $t6, 1       # Increment Y
    sub $t7, $t6, $t1      # $t7 = Y - startY
    ble $t7, $t3, rightLineLoop # Continue if not done
    
    # Draw bottom horizontal line
    move $t5, $t0          # $t5 = startX
    move $t6, $t1          # $t6 = startY
    add $t6, $t6, $t3      # $t6 = startY + N
    
bottomLineLoop:
    # Calculate pixel address
    la $t7, frameBuffer    # $t7 = base address
    lw $t8, displayWidth   # $t8 = display width
    mul $t8, $t6, $t8      # $t8 = Y * display width
    add $t8, $t8, $t5      # $t8 = Y * display width + X
    sll $t8, $t8, 2        # $t8 = 4 * (Y * display width + X)
    add $t7, $t7, $t8      # $t7 = address of current pixel
    
    sw $t4, 0($t7)         # Store color at current pixel
    
    addi $t5, $t5, 1       # Increment X
    sub $t7, $t5, $t0      # $t7 = X - startX
    ble $t7, $t2, bottomLineLoop # Continue if not done
    
    # Draw left vertical line
    move $t5, $t0          # $t5 = startX
    move $t6, $t1          # $t6 = startY
    
leftLineLoop:
    # Calculate pixel address
    la $t7, frameBuffer    # $t7 = base address
    lw $t8, displayWidth   # $t8 = display width
    mul $t8, $t6, $t8      # $t8 = Y * display width
    add $t8, $t8, $t5      # $t8 = Y * display width + X
    sll $t8, $t8, 2        # $t8 = 4 * (Y * display width + X)
    add $t7, $t7, $t8      # $t7 = address of current pixel
    
    sw $t4, 0($t7)         # Store color at current pixel
    
    addi $t6, $t6, 1       # Increment Y
    sub $t7, $t6, $t1      # $t7 = Y - startY
    ble $t7, $t3, leftLineLoop # Continue if not done
    
    # Draw arrow shaft
    lw $t0, startX         # $t0 = startX
    lw $t1, startY         # $t1 = startY
    lw $t2, M              # $t2 = width (M)
    lw $t3, N              # $t3 = height (N)
    lw $t4, arrowColor     # $t4 = arrow color
    lw $t5, arrowLength    # $t5 = arrow length
    
    # Calculate arrow shaft starting point
    add $t6, $t0, $t2      # $t6 = startX + M (right edge of rectangle)
    add $t7, $t1, $t3      # $t7 = startY + N (bottom edge of rectangle)
    srl $t8, $t3, 1        # $t8 = N / 2
    sub $t7, $t7, $t8      # $t7 = startY + N - N/2 (center of rectangle)
    
    # Draw arrow shaft
    move $t8, $t6          # $t8 = current X
    move $t9, $t7          # $t9 = current Y
    
arrowShaftLoop:
    # Calculate pixel address
    la $s0, frameBuffer    # $s0 = base address
    lw $s1, displayWidth   # $s1 = display width
    mul $s1, $t9, $s1      # $s1 = Y * display width
    add $s1, $s1, $t8      # $s1 = Y * display width + X
    sll $s1, $s1, 2        # $s1 = 4 * (Y * display width + X)
    add $s0, $s0, $s1      # $s0 = address of current pixel
    
    sw $t4, 0($s0)         # Store color at current pixel
    
    addi $t8, $t8, 1       # Increment X
    sub $s0, $t8, $t6      # $s0 = X - startX
    ble $s0, $t5, arrowShaftLoop # Continue if not done
    
    # Draw arrowhead
    lw $t0, startX         # $t0 = startX
    lw $t1, startY         # $t1 = startY
    lw $t2, M              # $t2 = width (M)
    lw $t3, N              # $t3 = height (N)
    lw $t4, arrowHeadColor # $t4 = arrowhead color
    lw $t5, arrowLength    # $t5 = arrow length
    lw $t6, arrowHeadSize  # $t6 = arrowhead size
    
    # Calculate arrowhead starting point
    add $t7, $t0, $t2      # $t7 = startX + M (right edge of rectangle)
    add $t7, $t7, $t5      # $t7 = startX + M + arrowLength (end of arrow shaft)
    add $t8, $t1, $t3      # $t8 = startY + N (bottom edge of rectangle)
    srl $t9, $t3, 1        # $t9 = N / 2
    sub $t8, $t8, $t9      # $t8 = startY + N - N/2 (center of rectangle)
    
    # Draw arrowhead
    sub $s0, $t8, $t6      # $s0 = center Y - arrowHeadSize (top of arrowhead)
    add $s1, $t8, $t6      # $s1 = center Y + arrowHeadSize (bottom of arrowhead)
    add $s2, $t7, $t6      # $s2 = arrowTip X
    
    # Draw arrowhead triangle
    move $s3, $t7          # $s3 = current X
    move $s4, $s0          # $s4 = current Y (top of arrowhead)
    
    # Calculate slope for top line
    li $s5, 1              # $s5 = X increment
    li $s6, 1              # $s6 = Y increment
    
arrowheadTopLoop:
    # Calculate pixel address
    la $s7, frameBuffer    # $s7 = base address
    lw $t0, displayWidth   # $t0 = display width
    mul $t0, $s4, $t0      # $t0 = Y * display width
    add $t0, $t0, $s3      # $t0 = Y * display width + X
    sll $t0, $t0, 2        # $t0 = 4 * (Y * display width + X)
    add $s7, $s7, $t0      # $s7 = address of current pixel
    
    sw $t4, 0($s7)         # Store color at current pixel
    
    addi $s3, $s3, 1       # Increment X
    addi $s4, $s4, 1       # Increment Y
    blt $s3, $s2, arrowheadTopLoop # Continue if not done
    
    # Draw bottom line of arrowhead
    move $s3, $t7          # $s3 = current X
    move $s4, $s1          # $s4 = current Y (bottom of arrowhead)
    
arrowheadBottomLoop:
    # Calculate pixel address
    la $s7, frameBuffer    # $s7 = base address
    lw $t0, displayWidth   # $t0 = display width
    mul $t0, $s4, $t0      # $t0 = Y * display width
    add $t0, $t0, $s3      # $t0 = Y * display width + X
    sll $t0, $t0, 2        # $t0 = 4 * (Y * display width + X)
    add $s7, $s7, $t0      # $s7 = address of current pixel
    
    sw $t4, 0($s7)         # Store color at current pixel
    
    addi $s3, $s3, 1       # Increment X
    addi $s4, $s4, -1      # Decrement Y
    blt $s3, $s2, arrowheadBottomLoop # Continue if not done
    
    # Fill the arrowhead triangle
    move $s3, $t7          # $s3 = current X
    
arrowheadFillLoop:
    move $s4, $s0          # $s4 = top Y
    addi $s4, $s4, 1       # Adjust to be inside the triangle
    
    # Calculate the height of the triangle at this X
    sub $t0, $s3, $t7      # $t0 = X - startX
    sll $t0, $t0, 1        # $t0 = 2 * (X - startX)
    add $s5, $s0, $t0      # $s5 = top Y + 2 * (X - startX)
    
    # Fill the column
arrowheadColumnLoop:
    # Calculate pixel address
    la $s7, frameBuffer    # $s7 = base address
    lw $t0, displayWidth   # $t0 = display width
    mul $t0, $s4, $t0      # $t0 = Y * display width
    add $t0, $t0, $s3      # $t0 = Y * display width + X
    sll $t0, $t0, 2        # $t0 = 4 * (Y * display width + X)
    add $s7, $s7, $t0      # $s7 = address of current pixel
    
    sw $t4, 0($s7)         # Store color at current pixel
    
    addi $s4, $s4, 1       # Increment Y
    blt $s4, $s5, arrowheadColumnLoop # Continue if not at bottom
    
    addi $s3, $s3, 1       # Move to next column
    blt $s3, $s2, arrowheadFillLoop # Continue if not at triangle tip
    
    # Exit program
    li $v0, 10             # Exit syscall
    syscall