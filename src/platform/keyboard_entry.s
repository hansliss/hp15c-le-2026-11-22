.syntax unified
.cpu arm7tdmi
.arm
.section .text.keyboard_boot,"ax",%progbits
.global keyboard_start
keyboard_start:
// Clear the scanner state and install the main stack guard before startup.
    mrs r3,cpsr
    orr r0, r3, #128
    msr cpsr_c, r0
    ldr r0,=0x200014
    ldr r1,=0x47554135
    str r1,[r0]
    ldr r0,=0x2007c4
    ldr r1,=0x200814
    mov r2,#0
1: str r2,[r0],#4
    cmp r0,r1
    bne 1b
    push {r3,r4,lr}
    bl keyboard_boot
    pop {r3,r4,lr}
    msr cpsr_c, r3
    ldr pc,=0x10ff28
.ltorg
.text
.global keyboard_scan_entry
keyboard_scan_entry:
    push {r4,lr}
    mov r4,sp
    bic sp,sp,#7
    bl keyboard_candidate_scan
    mov sp,r4
    pop {r4,pc}
.global keyboard_factory_entry
keyboard_factory_entry:
    push {r4,lr}
    mov r4,sp
    bic sp,sp,#7
    bl keyboard_factory_menu
    mov sp,r4
    pop {r4,pc}
.global keyboard_schedule
keyboard_schedule:
// Only timer 0 uses the profile interval.
    cmp r0,#0
    bne 2f
    push {r0-r4,lr}
    mov r4,sp
    bic sp,sp,#7
    bl keyboard_timer_units
    str r0,[r4,#4]
    mov sp,r4
    pop {r0-r4,lr}
2:  push {r2-r8, lr}  // Replay the replaced timer routine prologue.
    ldr pc,=0x110f44
.ltorg
.global keyboard_speed
keyboard_speed:
    ldr r12,=1900000
    cmp r0,r12
    movlo r0,r12
    push {r3-r9, lr}  // Replay the replaced clock routine prologue.
    ldr pc,=0x10fb80
.ltorg
