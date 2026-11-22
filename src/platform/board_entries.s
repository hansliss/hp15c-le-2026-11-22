.syntax unified
.cpu arm7tdmi
.arm
.text

/* Original callers may have a four-byte-aligned stack. Keep their live
 * scratch registers across the C call and return the result in r0. */
.macro board_entry name, target, continuation, scratch_result
.global \name
.type \name,%function
\name:
    push {r1-r4, r12, lr}
    mov r4, sp
    bic sp, sp, #7
    bl \target
    mov sp, r4
    pop {r1-r4, r12, lr}
.ifnb \scratch_result
    mov \scratch_result, r12
.endif
.ifb \continuation
    bx lr
.else
    b \continuation
.endif
.size \name, .-\name
.endm

board_entry board_masks_entry, board_init_field_masks
board_entry board_checksum_entry, board_image_checksum
board_entry board_contrast_entry, board_set_contrast
board_entry board_queue_empty_entry, board_key_queue_empty
board_entry board_queue_clear_entry, board_key_queue_clear
/* The original peek and add copied the caller's r12 to r1 and r0,
 * respectively, by popping their saved registers into different registers. */
board_entry board_queue_peek_entry, board_key_queue_peek, , r1
board_entry board_queue_get_entry, board_key_queue_get, board_queue_get_return
board_entry board_queue_add_entry, board_key_queue_add, , r0
