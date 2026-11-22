.syntax unified
.cpu arm7tdmi
.arm
.section .text.mixed_entry,"ax",%progbits

/* IAR callers require four-byte stack alignment; C requires eight bytes.
 * r4 holds the exact saved-frame SP and is preserved by the C callee.
 */
.global mixed_lcd_entry
.type mixed_lcd_entry,%function
mixed_lcd_entry:
    push {r4-r11, lr}
    mov r4, sp
    bic sp, sp, #7
    bl le_mixed_lcd_update
    mov sp, r4
    pop {r4-r11, pc}
.size mixed_lcd_entry, .-mixed_lcd_entry

/* Leave the surviving payload at its tested addresses. */
.space 0x94
