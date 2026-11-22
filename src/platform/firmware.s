// Fixed-layout ARM platform for the standalone C firmware.
// The .org gaps preserve addresses used by the retained platform and C adapters.
// Unclassified words are retained in place, including computed branch tables.
.syntax unified
.cpu arm7tdmi
.arm
.section .firmware,"ax",%progbits
.global firmware_start
firmware_start:
exception_vectors:
    ldr pc, [pc, #0x8c]
    ldr pc, [pc, #0x14]
    ldr pc, [pc, #0x10]
    ldr pc, [pc, #0xc]
    ldr pc, [pc, #0x8]
loc_00100014:
    b loc_00100014
    b irq_context_wrapper
    ldr pc, [pc, #-0x4]
fault_reset_pointer:
    .word 0x0011178c  // 0x100020

// Dispatch via the interrupt controller and restore the interrupted CPSR on return.
irq_context_wrapper:
    sub lr, lr, #4
    stmdb sp!, {lr}
    mrs lr, spsr
    push {r0, lr}
    ldr lr, [pc, #0x5c]
    ldr r0, [lr, #0x100]
    str lr, [lr, #0x100]
    msr CPSR_c, #19
    push {r1, r2, r3, r12, lr}
    mov lr, pc
    bx r0
    pop {r1, r2, r3, r12, lr}
    msr CPSR_c, #146
    ldr lr, [pc, #0x38]
    str lr, [lr, #0x130]
    pop {r0, lr}
    msr SPSR_fsxc, lr
    ldm sp!, {pc} ^

// Install the IRQ and supervisor stacks before jumping to the C scanner boot shim.
reset_entry:
    ldr r0, [pc, #0x28]
    ldr sp, [pc, #0x28]
    mov lr, pc
    bx r0
    msr CPSR_c, #210
    ldr sp, [pc, #0x1c]
    msr CPSR_c, #83
    ldr sp, [pc, #0x10]
    ldr r0, [pc, #0x14]
    bx r0
startup_literals:
    .word 0x0010006c  // 0x100094
    .word 0xfffff000
    .word 0x001117a4
    .word 0x002007c4
    .word 0x00200874  // 0x1000a4
    .word keyboard_start
    .zero 84  // Pad the vector region to the start of the Nut ROM.

// The build extracts and patches these Nut words from the supplied stock image.
nut_rom:
    .incbin "nut-rom.bin"
nut_rom_end:
    .org 0x7134  // C owns the Nut return stack.

// Fixed entry for the C field-cache rebuild.
nut_init_field_masks:
    b board_masks_entry
    .org 0xd1a0  // The C interpreter replaces the old ARM opcode bodies.

nut_interpreter_entry:
    // Align the native caller's stack for the C interpreter, then restore it.
    push {r4, lr}
    mov r4, sp
    bic sp, sp, #7
    bl le_mixed_dispatch
    mov sp, r4
    pop {r4, pc}
    .org 0xd1d8  // Former dispatch loop and literals.

// Reset the display request counter and blink flag, run Nut, then refresh the LCD.
nut_run_and_refresh:
    push {r3, r4, r5, lr}
    mov r4, r0
    mov r5, #0
    ldr r0, [pc, #0x28]
    str r5, [r0]
    mov r1, r4
    mov r0, #0
    bl nut_init_field_masks
    strb r5, [r4, #0x43]
    ldrb r1, [r4, #0x42]
    mov r0, r4
    bl nut_interpreter_entry
    mov r0, r4
    pop {r1, r4, r5, lr}
    b lcd_update
display_quota_counter_address:
    .word 0x00200010  // 0x10d214
loc_0010d218:
    push {r4, r5, r6, lr}
    ldr r4, [pc, #0x7c0]
    cmp r1, #0
    beq loc_0010d2e4
    cmp r0, #1
    blt loc_0010d258
    cmp r0, #27
    bge loc_0010d258
    ldr r5, [r4]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    orr r0, r5, r6, lsl r1
loc_0010d250:
    str r0, [r4]
    pop {r4, r5, r6, pc}
loc_0010d258:
    cmp r0, #27
    blt loc_0010d288
    cmp r0, #53
    bge loc_0010d288
    ldr r5, [r4, #0x8]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    orr r0, r5, r6, lsl r1
loc_0010d280:
    str r0, [r4, #0x8]
    pop {r4, r5, r6, pc}
loc_0010d288:
    cmp r0, #52
    blt loc_0010d2b8
    cmp r0, #79
    bge loc_0010d2b8
    ldr r5, [r4, #0x10]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    orr r0, r5, r6, lsl r1
loc_0010d2b0:
    str r0, [r4, #0x10]
    pop {r4, r5, r6, pc}
loc_0010d2b8:
    cmp r0, #79
    blt loc_0010d3a4
    cmp r0, #105
    bge loc_0010d3a4
    ldr r5, [r4, #0x18]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    orr r0, r5, r6, lsl r1
    b loc_0010d3a0
loc_0010d2e4:
    cmp r0, #1
    blt loc_0010d314
    cmp r0, #27
    bge loc_0010d314
    ldr r5, [r4]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    mvn r0, r6, lsl r1
    and r0, r0, r5
    b loc_0010d250
loc_0010d314:
    cmp r0, #27
    blt loc_0010d344
    cmp r0, #53
    bge loc_0010d344
    ldr r5, [r4, #0x8]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    mvn r0, r6, lsl r1
    and r0, r0, r5
    b loc_0010d280
loc_0010d344:
    cmp r0, #52
    blt loc_0010d374
    cmp r0, #79
    bge loc_0010d374
    ldr r5, [r4, #0x10]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    mvn r0, r6, lsl r1
    and r0, r0, r5
    b loc_0010d2b0
loc_0010d374:
    cmp r0, #79
    blt loc_0010d3a4
    cmp r0, #105
    bge loc_0010d3a4
    ldr r5, [r4, #0x18]
    mov r6, #1
    sub r0, r0, #1
    mov r1, #26
    bl integer_signed_divide
    mvn r0, r6, lsl r1
    and r0, r0, r5
loc_0010d3a0:
    str r0, [r4, #0x18]
loc_0010d3a4:
    pop {r4, r5, r6, pc}
    push {r4, r5, r6, r7, r8, r9, r10, lr}
    mov r4, r0
    mov r6, #0
    mov r7, #0
    mov r0, #0
    bl Lcd_Enable
    strb r6, [r4, #0x42]
    mvn r10, #175
    bic r10, r10, #128, #30
    mov r8, #1
    orr r8, r8, #-1526726656
    ldr r5, [pc, #0x604]
    b loc_0010d3e0
loc_0010d3dc:
    str r8, [r10]
loc_0010d3e0:
    ldm r5, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010d3dc
    bl KeyboardBufferClear
    mov r4, #192, #22
    orr r4, r4, #212, #28
    mov r0, r4
    bl software_wait
    ldr r0, [pc, #0x5d8]
    mvn r1, r6
    str r1, [r0]
    str r6, [r0, #0x4]
    str r1, [r0, #0x8]
    str r6, [r0, #0xc]
    str r1, [r0, #0x10]
    str r6, [r0, #0x14]
    str r1, [r0, #0x18]
    str r6, [r0, #0x1c]
    mov r0, r4
    bl software_wait
    b loc_0010d43c
loc_0010d438:
    str r8, [r10]
loc_0010d43c:
    bl KeyBuffEmpty
    cmp r0, #0
    bne loc_0010d438
    bl KeyBuffGetKey
    mov r9, r0
    mov r0, #1
    mov r1, #0
    mov r2, r9
    bl compiler_u64_shift_left_byte_count
    orr r6, r6, r0
    orr r7, r7, r1
    cmp r9, #39
    bhi loc_0010d998
    add r0, pc, #8
    lsl r9, r9, #1
    ldrh r0, [r0, r9]
    add pc, pc, r0, lsl #2
    .word 0x00190013  // 0x10d480
    .word 0x002b0022
    .word 0x003d0034
    .word 0x004f0046
    .word 0x00610058
    .word 0x0073006a
    .word 0x007f0079
    .word 0x008b0085
    .word 0x00970091
    .word 0x00a3009d
    .word 0x00b500a9
    .word 0x00cd00c1
    .word 0x00e500d9
    .word 0x010000f4
    .word 0x0118010c
    .word 0x012a0124
    .word 0x0130012d
    .word 0x01450136
    .word 0x013c0139
    .word 0x0142013f
    .word 0xe3a01000
    .word 0xe3a00002
    .word 0xebffff4e
    .word 0xe3a01000
    .word 0xe3a00003
    .word 0xea00012a
    .word 0xe3a01000
    .word 0xe3a0001e
    .word 0xebffff48
    .word 0xe3a01000
    .word 0xe3a00005
    .word 0xebffff45
    .word 0xe3a01000
    .word 0xe3a00004
    .word 0xea000121
    .word 0xe3a01000
    .word 0xe3a00006
    .word 0xebffff3f
    .word 0xe3a01000
    .word 0xe3a00007
    .word 0xebffff3c
    .word 0xe3a01000
    .word 0xe3a00008
    .word 0xea000118
    .word 0xe3a01000
    .word 0xe3a00023
    .word 0xebffff36
    .word 0xe3a01000
    .word 0xe3a0000a
    .word 0xebffff33
    .word 0xe3a01000
    .word 0xe3a00009
    .word 0xea00010f
    .word 0xe3a01000
    .word 0xe3a0000b
    .word 0xebffff2d
    .word 0xe3a01000
    .word 0xe3a0000c
    .word 0xebffff2a
    .word 0xe3a01000
    .word 0xe3a0000d
    .word 0xea000106
    .word 0xe3a01000
    .word 0xe3a00028
    .word 0xebffff24
    .word 0xe3a01000
    .word 0xe3a0000f
    .word 0xebffff21
    .word 0xe3a01000
    .word 0xe3a0000e
    .word 0xea0000fd
    .word 0xe3a01000
    .word 0xe3a00010
    .word 0xebffff1b
    .word 0xe3a01000
    .word 0xe3a00011
    .word 0xebffff18
    .word 0xe3a01000
    .word 0xe3a00012
    .word 0xea0000f4
    .word 0xe3a01000
    .word 0xe3a0002d
    .word 0xebffff12
    .word 0xe3a01000
    .word 0xe3a00014
    .word 0xebffff0f
    .word 0xe3a01000
    .word 0xe3a00013
    .word 0xea0000eb
    .word 0xe3a01000
    .word 0xe3a00015
    .word 0xebffff09
    .word 0xe3a01000
    .word 0xe3a00016
    .word 0xebffff06
    .word 0xe3a01000
    .word 0xe3a00017
    .word 0xea0000e2
    .word 0xe3a01000
    .word 0xe3a00032
    .word 0xebffff00
    .word 0xe3a01000
    .word 0xe3a00019
    .word 0xebfffefd
    .word 0xe3a01000
    .word 0xe3a00018
    .word 0xea0000d9
    .word 0xe3a01000
    .word 0xe3a00050
    .word 0xebfffef7
    .word 0xe3a01000
    .word 0xe3a0001c
    .word 0xebfffef4
    .word 0xe3a01000
    .word 0xe3a0001d
    .word 0xea0000d0
    .word 0xe3a01000
    .word 0xe3a0001f
    .word 0xebfffeee
    .word 0xe3a01000
    .word 0xe3a00020
    .word 0xea0000ca
    .word 0xe3a01000
    .word 0xe3a00021
    .word 0xebfffee8
    .word 0xe3a01000
    .word 0xe3a00022
    .word 0xea0000c4
    .word 0xe3a01000
    .word 0xe3a00024
    .word 0xebfffee2
    .word 0xe3a01000
    .word 0xe3a00025
    .word 0xea0000be
    .word 0xe3a01000
    .word 0xe3a00026
    .word 0xebfffedc
    .word 0xe3a01000
    .word 0xe3a00027
    .word 0xea0000b8
    .word 0xe3a01000
    .word 0xe3a00029
    .word 0xebfffed6
    .word 0xe3a01000
    .word 0xe3a0002a
    .word 0xea0000b2
    .word 0xe3a01000
    .word 0xe3a0002b
    .word 0xebfffed0
    .word 0xe3a01000
    .word 0xe3a0002c
    .word 0xea0000ac
    .word 0xe3a01000
    .word 0xe3a0002e
    .word 0xebfffeca
    .word 0xe3a01000
    .word 0xe3a0002f
    .word 0xea0000a6
    .word 0xe3a01000
    .word 0xe3a00030
    .word 0xebfffec4
    .word 0xe3a01000
    .word 0xe3a00031
    .word 0xea0000a0
    .word 0xe3a01000
    .word 0xe3a00033
    .word 0xebfffebe
    .word 0xe3a01000
    .word 0xe3a00034
    .word 0xea00009a
    .word 0xe3a01000
    .word 0xe3a00036
    .word 0xebfffeb8
    .word 0xe3a01000
    .word 0xe3a00037
    .word 0xebfffeb5
    .word 0xe3a01000
    .word 0xe3a00052
    .word 0xebfffeb2
    .word 0xe3a01000
    .word 0xe3a00051
    .word 0xea00008e
    .word 0xe3a01000
    .word 0xe3a00038
    .word 0xebfffeac
    .word 0xe3a01000
    .word 0xe3a00039
    .word 0xebfffea9
    .word 0xe3a01000
    .word 0xe3a0003a
    .word 0xebfffea6
    .word 0xe3a01000
    .word 0xe3a00054
    .word 0xea000082
    .word 0xe3a01000
    .word 0xe3a0003b
    .word 0xebfffea0
    .word 0xe3a01000
    .word 0xe3a0003c
    .word 0xebfffe9d
    .word 0xe3a01000
    .word 0xe3a00057
    .word 0xebfffe9a
    .word 0xe3a01000
    .word 0xe3a00056
    .word 0xea000076
    .word 0xe3a01000
    .word 0xe3a0003d
    .word 0xebfffe94
    .word 0xe3a01000
    .word 0xe3a0003e
    .word 0xebfffe91
    .word 0xe3a01000
    .word 0xe3a0003f
    .word 0xebfffe8e
    .word 0xe3a01000
    .word 0xe3a00059
    .word 0xea00006a
    .word 0xe3a01000
    .word 0xe3a00040
    .word 0xebfffe88
    .word 0xe3a01000
    .word 0xe3a00041
    .word 0xebfffe85
    .word 0xe3a01000
    .word 0xe3a0005c
    .word 0xebfffe82
    .word 0xe3a01000
    .word 0xe3a0005b
    .word 0xea00005e
    .word 0xe3a01000
    .word 0xe3a00042
    .word 0xebfffe7c
    .word 0xe3a01000
    .word 0xe3a00043
    .word 0xebfffe79
    .word 0xe3a01000
    .word 0xe3a00044
    .word 0xebfffe76
    .word 0xe3a01000
    .word 0xe3a0005e
    .word 0xebfffe73
    .word 0xe3a01008
    .word 0xe1877001
    .word 0xea000050
    .word 0xe3a01000
    .word 0xe3a00045
    .word 0xebfffe6d
    .word 0xe3a01000
    .word 0xe3a00046
    .word 0xebfffe6a
    .word 0xe3a01000
    .word 0xe3a00061
    .word 0xebfffe67
    .word 0xe3a01000
    .word 0xe3a00060
    .word 0xea000043
    .word 0xe3a01000
    .word 0xe3a00047
    .word 0xebfffe61
    .word 0xe3a01000
    .word 0xe3a00048
    .word 0xebfffe5e
    .word 0xe3a01000
    .word 0xe3a00049
    .word 0xebfffe5b
    .word 0xe3a01000
    .word 0xe3a00063
    .word 0xea000037
    .word 0xe3a01000
    .word 0xe3a0004a
    .word 0xebfffe55
    .word 0xe3a01000
    .word 0xe3a0004b
    .word 0xebfffe52
    .word 0xe3a01000
    .word 0xe3a00066
    .word 0xebfffe4f
    .word 0xe3a01000
    .word 0xe3a00065
    .word 0xea00002b
    .word 0xe3a01000
    .word 0xe3a0004c
    .word 0xebfffe49
    .word 0xe3a01000
    .word 0xe3a0004d
    .word 0xebfffe46
    .word 0xe3a01000
    .word 0xe3a0004e
    .word 0xebfffe43
    .word 0xe3a01000
    .word 0xe3a00068
    .word 0xea00001f
    .word 0xe3a01000
    .word 0xe3a0001a
    .word 0xebfffe3d
    .word 0xe3a01000
    .word 0xe3a0004f
    .word 0xea000019
    .word 0xe3a01000
    .word 0xe3a00053
    .word 0xea000016
    .word 0xe3a01000
    .word 0xe3a00055
    .word 0xea000013
    .word 0xe3a01000
    .word 0xe3a00058
    .word 0xebfffe31
    .word 0xe3a01000
    .word 0xe3a0005a
    .word 0xea00000d
    .word 0xe3a01000
    .word 0xe3a0005d
    .word 0xea00000a
    .word 0xe3a01000
    .word 0xe3a0005f
    .word 0xea000007
    .word 0xe3a01000
    .word 0xe3a00062
    .word 0xea000004
    .word 0xe3a01000
    .word 0xe3a00064
    .word 0xea000001
    .word 0xe3a01000
    .word 0xe3a00067
    .word 0xebfffe1f
loc_0010d998:
    cmp r7, #255
    mvneq r0, #0
    cmpeq r6, r0
    bne loc_0010d43c
loc_0010d9a8:
    ldm r5, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010d9a8
    bl KeyboardBufferClear
    mov r0, r4
    bl software_wait
    b loc_0010d9cc
loc_0010d9c8:
    str r8, [r10]
loc_0010d9cc:
    ldm r5, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010d9c8
    pop {r4, r5, r6, r7, r8, r9, r10, pc}
    .word 0x00200878  // 0x10d9e0
    .word 0xfffb4200
render_character:
    push {r4, lr}
    add r2, r0, r0, lsr #31
    asr r2, r2, #1
    mov r12, #36
    mul r3, r12, r2
    ldr r12, [pc, #0xa30]
    add r4, r3, r12
    sub r1, r1, #44
    cmp r1, #73
    bhi loc_0010e3c4
    add lr, pc, #8
    lsl r1, r1, #1
    ldrh lr, [lr, r1]
    add pc, pc, lr, lsl #2
glyph_switch_offsets:
    .hword (loc_0010e0e8 - (glyph_switch_offsets + 4))/4  // char 44 ','
    .hword (loc_0010e054 - (glyph_switch_offsets + 4))/4  // char 45 '-'
    .hword (loc_0010e0dc - (glyph_switch_offsets + 4))/4  // char 46 '.'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 47 '/'
    .hword (loc_0010e374 - (glyph_switch_offsets + 4))/4  // char 48 '0'
    .hword (loc_0010e0f4 - (glyph_switch_offsets + 4))/4  // char 49 '1'
    .hword (loc_0010e144 - (glyph_switch_offsets + 4))/4  // char 50 '2'
    .hword (loc_0010e194 - (glyph_switch_offsets + 4))/4  // char 51 '3'
    .hword (loc_0010e1e4 - (glyph_switch_offsets + 4))/4  // char 52 '4'
    .hword (loc_0010df88 - (glyph_switch_offsets + 4))/4  // char 53 '5'
    .hword (loc_0010e234 - (glyph_switch_offsets + 4))/4  // char 54 '6'
    .hword (loc_0010e284 - (glyph_switch_offsets + 4))/4  // char 55 '7'
    .hword (loc_0010e2d4 - (glyph_switch_offsets + 4))/4  // char 56 '8'
    .hword (loc_0010e324 - (glyph_switch_offsets + 4))/4  // char 57 '9'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 58 ':'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 59 ';'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 60 '<'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 61 '='
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 62 '>'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 63 '?'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 64 '@'
    .hword (loc_0010dab4 - (glyph_switch_offsets + 4))/4  // char 65 'A'
    .hword (loc_0010db04 - (glyph_switch_offsets + 4))/4  // char 66 'B'
    .hword (loc_0010db80 - (glyph_switch_offsets + 4))/4  // char 67 'C'
    .hword (loc_0010dbc4 - (glyph_switch_offsets + 4))/4  // char 68 'D'
    .hword (loc_0010dd24 - (glyph_switch_offsets + 4))/4  // char 69 'E'
    .hword (loc_0010dc4c - (glyph_switch_offsets + 4))/4  // char 70 'F'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 71 'G'
    .hword (loc_0010dce0 - (glyph_switch_offsets + 4))/4  // char 72 'H'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 73 'I'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 74 'J'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 75 'K'
    .hword (loc_0010ddac - (glyph_switch_offsets + 4))/4  // char 76 'L'
    .hword (loc_0010ddf0 - (glyph_switch_offsets + 4))/4  // char 77 'M'
    .hword (loc_0010de78 - (glyph_switch_offsets + 4))/4  // char 78 'N'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 79 'O'
    .hword (loc_0010e098 - (glyph_switch_offsets + 4))/4  // char 80 'P'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 81 'Q'
    .hword (loc_0010df00 - (glyph_switch_offsets + 4))/4  // char 82 'R'
    .hword (loc_0010df88 - (glyph_switch_offsets + 4))/4  // char 83 'S'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 84 'T'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 85 'U'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 86 'V'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 87 'W'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 88 'X'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 89 'Y'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 90 'Z'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 91 '['
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 92 '\\'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 93 ']'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 94 '^'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 95 '_'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 96 '`'
    .hword (loc_0010dab4 - (glyph_switch_offsets + 4))/4  // char 97 'a'
    .hword (loc_0010db04 - (glyph_switch_offsets + 4))/4  // char 98 'b'
    .hword (loc_0010db30 - (glyph_switch_offsets + 4))/4  // char 99 'c'
    .hword (loc_0010dbc4 - (glyph_switch_offsets + 4))/4  // char 100 'd'
    .hword (loc_0010dc08 - (glyph_switch_offsets + 4))/4  // char 101 'e'
    .hword (loc_0010dc4c - (glyph_switch_offsets + 4))/4  // char 102 'f'
    .hword (loc_0010e324 - (glyph_switch_offsets + 4))/4  // char 103 'g'
    .hword (loc_0010dc90 - (glyph_switch_offsets + 4))/4  // char 104 'h'
    .hword (loc_0010dd68 - (glyph_switch_offsets + 4))/4  // char 105 'i'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 106 'j'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 107 'k'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 108 'l'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 109 'm'
    .hword (loc_0010de34 - (glyph_switch_offsets + 4))/4  // char 110 'n'
    .hword (loc_0010debc - (glyph_switch_offsets + 4))/4  // char 111 'o'
    .hword (loc_0010e098 - (glyph_switch_offsets + 4))/4  // char 112 'p'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 113 'q'
    .hword (loc_0010df44 - (glyph_switch_offsets + 4))/4  // char 114 'r'
    .hword (loc_0010e3c4 - (glyph_switch_offsets + 4))/4  // char 115 's'
    .hword (loc_0010dfcc - (glyph_switch_offsets + 4))/4  // char 116 't'
    .hword (loc_0010e010 - (glyph_switch_offsets + 4))/4  // char 117 'u'
loc_0010dab4:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
loc_0010dadc:
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
loc_0010daf4:
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010db04:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    b loc_0010dadc
loc_0010db30:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
loc_0010db70:
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010db80:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e41c
loc_0010dbc4:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010daf4
loc_0010dc08:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010db70
loc_0010dc4c:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010daf4
loc_0010dc90:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
loc_0010dcd0:
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010dce0:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010daf4
loc_0010dd24:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010db70
loc_0010dd68:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010e41c
loc_0010ddac:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e41c
loc_0010ddf0:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e41c
loc_0010de34:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e41c
loc_0010de78:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010daf4
loc_0010debc:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010db70
loc_0010df00:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010daf4
loc_0010df44:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e41c
loc_0010df88:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010daf4
loc_0010dfcc:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010db70
loc_0010e010:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010daf4
loc_0010e054:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    b loc_0010dcd0
loc_0010e098:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    b loc_0010daf4
loc_0010e0dc:
    mov r1, #1
    ldr r0, [r4, #0x1c]
    b loc_0010e42c
loc_0010e0e8:
    mov r1, #1
loc_0010e0ec:
    ldr r0, [r4, #0x20]
    b loc_0010e42c
loc_0010e0f4:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #0
    b loc_0010e428
loc_0010e144:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e194:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e1e4:
    mov r1, #0
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e234:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e284:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #0
    b loc_0010e428
loc_0010e2d4:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e324:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #1
    b loc_0010e428
loc_0010e374:
    mov r1, #1
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #1
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #0
    b loc_0010e428
loc_0010e3c4:
    subs r0, r0, r2, lsl #1
    mov r1, #0
    beq loc_0010e3e0
    ldr r0, [r4, #0x1c]
    bl loc_0010d218
    mov r1, #0
    b loc_0010e0ec
loc_0010e3e0:
    ldr r0, [r3, r12]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x4]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x8]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0xc]
    bl loc_0010d218
    mov r1, #0
    ldr r0, [r4, #0x10]
    bl loc_0010d218
    mov r1, #0
loc_0010e41c:
    ldr r0, [r4, #0x14]
    bl loc_0010d218
    mov r1, #0
loc_0010e428:
    ldr r0, [r4, #0x18]
loc_0010e42c:
    pop {r4, lr}
    b loc_0010d218
    .word 0x001112ac  // 0x10e434
loc_0010e438:
    push {r3, r4, r5, lr}
    mov r4, r0
    mov r5, #0
loc_0010e444:
    ldrb r1, [r5, r4]
    mov r0, r5
    bl render_character
    add r5, r5, #1
    cmp r5, #20
    blt loc_0010e444
    pop {r0, r4, r5, pc}
    push {r4, r5, r6, r7, r8, r9, r10, lr}
    sub sp, sp, #48
    mov r4, r0
    mov r0, #0
    bl Lcd_Enable
    mov r0, #0
    strb r0, [r4, #0x42]
    mvn r4, #175
    bic r4, r4, #128, #30
    mov r5, #1
    orr r5, r5, #-1526726656
    ldr r6, [pc, #0x204]
    b loc_0010e498
loc_0010e494:
    str r5, [r4]
loc_0010e498:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010e494
    ldr r7, [pc, #0x1ec]
    add r0, sp, #24
    ldm r7!, {r1, r2, r3, r8, r12, lr}
    stm r0!, {r1, r2, r3, r8, r12, lr}
    sub r7, r7, #24
    bl image_checksum
    add r1, sp, #24
    and r2, r0, #15
    add r2, r2, r7
    ldrb r2, [r2, #0x30]
    strb r2, [r1, #0xa]
    add r0, r7, r0, asr #4
    ldrb r0, [r0, #0x30]
    strb r0, [r1, #0xc]
    ldr r0, [pc, #0x1b8]
    ldrb r0, [r0]
    and r2, r0, #15
    add r2, r2, r7
    ldrb r2, [r2, #0x30]
    strb r2, [sp, #0x26]
    add r0, r7, r0, asr #4
    ldrb r0, [r0, #0x30]
    strb r0, [r1, #0x10]
    add r0, sp, #24
    bl loc_0010e438
    b loc_0010e514
loc_0010e510:
    str r5, [r4]
loc_0010e514:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010e510
    bl KeyboardBufferClear
    mov r8, #192, #22
    orr r8, r8, #212, #28
    mov r0, r8
    bl software_wait
    b loc_0010e540
loc_0010e53c:
    str r5, [r4]
loc_0010e540:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e53c
    mov r0, sp
    add r1, r7, #24
    ldm r1!, {r2, r3, r9, r10, r12, lr}
    stm r0!, {r2, r3, r9, r10, r12, lr}
    ldr r0, [pc, #0x13c]
    ldm r0, {r0, r1}
    mov r2, r0
    mov r3, r1
    mvn r0, #0
    bic r1, r0, #240, #8
    and r0, r2, r0
    and r1, r3, r1
    tst r0, #1
    lsrne r0, r0, #28
    orrne r2, r0, r1, lsl #4
    moveq r2, r1
    lsr r0, r2, #12
    and r0, r0, #15
    add r0, r0, #48
    strb r0, [sp]
    lsr r0, r2, #8
    and r0, r0, #15
    add r0, r0, #48
    strb r0, [sp, #0x2]
    lsr r1, r2, #4
    and r1, r1, #15
    add r1, r1, #48
    strb r1, [sp, #0x4]
    and r1, r2, #15
    add r1, r1, #48
    strb r1, [sp, #0x6]
    mov r1, #48
    add r1, r1, r2, lsr #28
    strb r1, [sp, #0xa]
    lsr r1, r2, #24
    and r1, r1, #15
    add r1, r1, #48
    strb r1, [sp, #0xc]
    lsr r1, r2, #20
    and r1, r1, #15
    add r1, r1, #48
    strb r1, [sp, #0x10]
    lsr r0, r2, #16
    and r0, r0, #15
    add r0, r0, #48
    strb r0, [sp, #0x12]
    mov r0, sp
    bl loc_0010e438
    b loc_0010e618
loc_0010e614:
    str r5, [r4]
loc_0010e618:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010e614
    bl KeyboardBufferClear
    mov r0, r8
    bl software_wait
    b loc_0010e63c
loc_0010e638:
    str r5, [r4]
loc_0010e63c:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e638
    add r0, r7, #68
    bl loc_0010e438
    b loc_0010e65c
loc_0010e658:
    str r5, [r4]
loc_0010e65c:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010e658
    bl KeyboardBufferClear
    mov r0, r8
    bl software_wait
    b loc_0010e680
loc_0010e67c:
    str r5, [r4]
loc_0010e680:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e67c
    add sp, sp, #48
    pop {r4, r5, r6, r7, r8, r9, r10, pc}
    .word 0x00200878  // 0x10e698
    .word 0x00111a64
    .word 0x00111c98
    .word 0x00111c80
    push {r3, r4, r5, r6, r7, r8, r9, r10, r11, lr}
    mov r7, r0
    mvn r4, #175
    bic r4, r4, #128, #30
    mov r5, #1
    orr r5, r5, #-1526726656
    ldr r6, [pc, #0x14c]
    b loc_0010e6cc
loc_0010e6c8:
    str r5, [r4]
loc_0010e6cc:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_0010e6c8
    bl KeyboardBufferClear
    mov r0, #0
    bl Lcd_Enable
    mov r8, #0
    strb r8, [r7, #0x42]
    mov r11, #1
    mov r9, #192, #22
    orr r9, r9, #212, #28
    ldr r7, [pc, #0x114]
    mvn r10, r8
loc_0010e704:
    str r10, [r7]
    str r8, [r7, #0x4]
    str r10, [r7, #0x8]
    str r8, [r7, #0xc]
    str r10, [r7, #0x10]
    str r8, [r7, #0x14]
    str r10, [r7, #0x18]
    str r8, [r7, #0x1c]
    mov r0, r9
    bl software_wait
    b loc_0010e734
loc_0010e730:
    str r5, [r4]
loc_0010e734:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e730
    cmp r1, #0
    cmpeq r0, #64, #16
    bne loc_0010e810
    mov r0, #0
    mov r1, #1
loc_0010e758:
    orr r0, r0, r11, lsl r1
    add r1, r1, #2
    cmp r1, #26
    blt loc_0010e758
    str r0, [r7]
    str r0, [r7, #0x8]
    str r0, [r7, #0x10]
    str r0, [r7, #0x18]
    mov r0, r9
    bl software_wait
    b loc_0010e788
loc_0010e784:
    str r5, [r4]
loc_0010e788:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e784
    cmp r1, #0
    cmpeq r0, #64, #16
    bne loc_0010e810
    mov r0, #0
loc_0010e7a8:
    orr r0, r0, r11, lsl r1
    add r1, r1, #2
    cmp r1, #26
    blt loc_0010e7a8
    str r0, [r7]
    str r0, [r7, #0x8]
    str r0, [r7, #0x10]
    str r0, [r7, #0x18]
    mov r0, r9
    bl software_wait
    b loc_0010e7d8
loc_0010e7d4:
    str r5, [r4]
loc_0010e7d8:
    ldm r6, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e7d4
    cmp r1, #0
    cmpeq r0, #64, #16
    bne loc_0010e810
    cmp r1, #0
    cmpeq r0, #0
    beq loc_0010e704
    cmp r1, #0
    cmpeq r0, #64, #16
    beq loc_0010e704
    bl KeyboardBufferClear
loc_0010e810:
    pop {r0, r4, r5, r6, r7, r8, r9, r10, r11, pc}
    .word 0x00200878  // 0x10e814
    .word 0xfffb4200

// The C menu owns tuning and calls the retained factory diagnostics.
factory_test_menu:
    b keyboard_factory_entry
    .org 0xf964  // Former factory menu and ARM dispatch table.

loc_0010f964:
    push {r4, lr}
    mov r4, r0
    bl loc_00111708
    bl loc_0011166c
    bl loc_00111768
    and r1, r0, #15
    and r2, r4, #15
    add r1, r2, r1
    cmp r1, #10
    addge r1, r1, #6
    and r2, r0, #240
    and r3, r4, #240
    add r2, r3, r2
    add r1, r2, r1
    cmp r1, #96
    addge r1, r1, #160
    and r2, r0, #240, #28
    and r3, r4, #240, #28
    add r2, r3, r2
    add r1, r2, r1
    cmp r1, #160, #28
    addge r1, r1, #96, #28
    and r2, r0, #240, #24
    and r3, r4, #240, #24
    add r2, r3, r2
    add r1, r2, r1
    cmp r1, #96, #24
    addge r1, r1, #160, #24
    and r2, r0, #240, #20
    and r3, r4, #240, #20
    add r2, r3, r2
    add r1, r2, r1
    cmp r1, #160, #20
    addge r1, r1, #96, #20
    and r0, r0, #240, #16
    and r2, r4, #240, #16
    add r0, r2, r0
    add r0, r0, r1
    cmp r0, #144, #18
    subge r0, r0, #144, #18
    ldr r3, [pc, #0x14]
    mov r1, #255
    and r2, r1, r0, lsr #16
    and r1, r1, r0, lsr #8
    and r0, r0, #255
    pop {r4, lr}
    b loc_0011173c
    .word 0x00808080  // 0x10fa20
loc_0010fa24:
    push {r3, r4, r5, lr}
    ldr r4, [pc, #0x770]
    ldr r0, [r4, #0x8]
    bl keyboard_clock_entry
    mvn r5, #0
    mvn r0, #219
    bic r0, r0, #224, #28
    str r5, [r0]
    bl Lcd_Disable
    mov r0, #0
    mov r2, #1
    orr r2, r2, #-1526726656
    b loc_0010fa5c
loc_0010fa58:
    mov r0, #0
loc_0010fa5c:
    mov r1, #44
    orr r1, r1, #192, #28
    str r2, [r1, #-0xedc]
    mov r1, #192, #28
    ldr r1, [r1, #-0xedc]
    tst r1, #64, #26
    beq loc_0010fa58
    add r0, r0, #1
    cmp r0, #1000
    blt loc_0010fa5c
    mov r0, #3056
    mov r1, #0
    str r1, [r0, #-0xedc]
    mov r0, #0
    bl loc_00110e5c
    mov r0, #1
    bl loc_00110e5c
    mov r0, #2
    bl loc_00110e5c
    mov r0, #116, #28
    str r5, [r0, #-0xedc]
    mov r0, #1776
    str r5, [r0, #-0xedc]
    sub r0, r0, #20
    str r5, [r0, #-0xedc]
    ldr r0, [r4, #0xc]
    asr r1, r0, #9
    add r0, r0, r1, lsr #22
    asr r0, r0, #10
    asr r1, r0, #1
    add r0, r0, r1, lsr #30
    asr r0, r0, #2
    bl software_wait
    mov r0, #2800
    mov r1, #16
    str r1, [r0, #-0xedc]
    orr r0, r0, #260
    ldr r0, [r0, #-0xedc]
    mov r1, #-1526726656
    orr r1, r1, #128, #22
    orr r0, r1, r0
    mov r1, #244
    orr r1, r1, #176, #28
    str r0, [r1, #-0xedc]
    bl loc_00111708
    mov r0, #248
    orr r0, r0, #176, #28
    ldr r0, [r0, #-0xedc]
    bic r0, r0, #8
    mov r1, #248
    orr r1, r1, #176, #28
    str r0, [r1, #-0xedc]
    ldr r0, [r1, #-0xedc]
    bic r0, r0, #112, #24
    str r0, [r1, #-0xedc]
    ldr r0, [r1, #-0xedc]
    bic r0, r0, #112, #28
    str r0, [r1, #-0xedc]
    ldr r0, [r1, #-0xedc]
    orr r0, r0, #1
    str r0, [r1, #-0xedc]
    orr r0, r1, #4
    ldr r0, [r0, #-0xedc]
    lsr r0, r0, #16
    lsl r0, r0, #16
    orr r1, r1, #4
    str r0, [r1, #-0xedc]
    bic r0, r1, #16
    mov r1, #4
    orr r1, r1, #-1526726656
supc_backup_on_only_store:
    str r1, [r0, #-0xedc]
loc_0010fb78:
    b loc_0010fb78
keyboard_clock_entry:
    b keyboard_speed
    ldr r5, [pc, #0x618]
    ldr r2, [r5, #0x8]
    cmp r0, #1
    movlt r0, r2
    ldr r1, [pc, #0x214]
    cmp r0, r1
    bge loc_0010fba8
    ldrb r1, [r5, #0x10]
    cmp r1, #0
    beq loc_0010fbac
loc_0010fba8:
    ldr r0, [pc, #0x5f4]
loc_0010fbac:
    ldr r1, [r5, #0x4]
    cmp r0, r1
    beq loc_0010fda8
    ldr r4, [r5, #0xc]
    str r0, [r5, #0x4]
    ldr r8, [r5]
    mov r6, #1
    orr r6, r6, #48896
    mvn r7, #215
    bic r7, r7, #192, #30
    cmp r2, r0
    bge loc_0010fcd0
    mov r9, #0
    ldr r1, [pc, #0x1c8]
    b loc_0010fbf0
loc_0010fbe8:
    lsl r0, r0, #1
    add r9, r9, #1
loc_0010fbf0:
    cmp r0, r1
    blt loc_0010fbe8
    cmp r9, #7
    movge r9, #6
    mov r1, r8
    bl integer_signed_divide
    sub r0, r0, #1
    cmp r0, #128, #28
    lsrge r0, r7, #21
    .inst 0xe0010098  // Retained encoding at 0x10fc14
    asr r1, r1, r9
    str r1, [r5, #0xc]
    mov r2, #824
    ldr r2, [r2, #-0x3d8]
    mov r3, #0
    ldr r12, [pc, #0x180]
    cmp r1, r12
    movge r1, #1
    movlt r1, #0
    bic r2, r2, #240, #28
    orrs r1, r1, r2
    movne r3, #64, #30
    mov r1, #824
    str r3, [r1, #-0x3d8]
    mov r1, #112, #12
    orr r1, r1, #16711680
    and r0, r1, r0, lsl #16
    orr r0, r6, r0
    str r0, [r7]
loc_0010fc64:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #2
    beq loc_0010fc64
loc_0010fc74:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    beq loc_0010fc74
    mov r0, #8
    ldr r0, [r0, #-0x3d8]
    bic r0, r0, #28
    orr r0, r0, r9, lsl #2
    mov r1, #8
    str r0, [r1, #-0x3d8]
loc_0010fc9c:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    beq loc_0010fc9c
    ldr r0, [r1, #-0x3d8]
    bic r0, r0, #3
    orr r0, r0, #2
    str r0, [r1, #-0x3d8]
loc_0010fcbc:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    bne loc_0010fda0
    b loc_0010fcbc
loc_0010fcd0:
    cmp r8, r0
    mov r1, #0
    bge loc_0010fd2c
    b loc_0010fce8
loc_0010fce0:
    lsl r0, r0, #1
    add r1, r1, #1
loc_0010fce8:
    cmp r0, r2
    blt loc_0010fce0
    cmp r1, #7
    movge r1, #6
    asr r0, r2, r1
    str r0, [r5, #0xc]
loc_0010fd00:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    beq loc_0010fd00
    mov r0, #8
    ldr r0, [r0, #-0x3d8]
    bic r0, r0, #3
    orr r0, r0, #1
    b loc_0010fd50
loc_0010fd24:
    lsl r0, r0, #1
    add r1, r1, #1
loc_0010fd2c:
    cmp r0, r8
    blt loc_0010fd24
    cmp r1, #7
    movge r1, #6
    asr r0, r8, r1
    str r0, [r5, #0xc]
    mov r0, #8
    ldr r0, [r0, #-0x3d8]
    bic r0, r0, #3
loc_0010fd50:
    mov r2, #8
    str r0, [r2, #-0x3d8]
loc_0010fd58:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    beq loc_0010fd58
    ldr r0, [r2, #-0x3d8]
    bic r0, r0, #28
    orr r0, r0, r1, lsl #2
    str r0, [r2, #-0x3d8]
loc_0010fd78:
    mov r0, #64
    ldr r0, [r0, #-0x3d8]
    tst r0, #8
    beq loc_0010fd78
    str r6, [r7]
    mov r0, #824
    ldr r0, [r0, #-0x3d8]
    bic r0, r0, #240, #28
    mov r1, #824
    str r0, [r1, #-0x3d8]
loc_0010fda0:
    mov r0, r4
    bl loc_00111088
loc_0010fda8:
    pop {r0, r4, r5, r6, r7, r8, r9, pc}
    .word 0x02255101  // 0x10fdac
    .word 0x0112a880
    .word 0x00e4e1c1

// Fixed entry for the C flash checksum routine.
image_checksum:
    b board_checksum_entry
    .org 0xfdf8
battery_test_voltage:
    push {r4, r5, r6, lr}
    sub r5, r0, #19
    sub r4, r1, #19
    cmp r4, #17
    movge r4, #16
    cmp r5, #0
    bpl loc_0010fe20
    mov r5, #0
    b loc_0010fe20
loc_0010fe1c:
    add r5, r5, #1
loc_0010fe20:
    mvn r6, #235
    bic r6, r6, #128, #30
    cmp r4, r5
    blt loc_0010fe84
    orr r0, r5, #64, #30
supc_brownout_config_store:
    str r0, [r6]
    ldr r0, [pc, #0x54]
    ldr r0, [r0]
    mov r1, #20
    bl integer_signed_divide
    asr r1, r0, #9
    add r0, r0, r1, lsr #22
    asr r0, r0, #10
    asr r1, r0, #1
    add r0, r0, r1, lsr #30
    asr r0, r0, #2
    bl software_wait
    mov r0, #16
    ldr r0, [r0, #-0x2ec]
    tst r0, #64
    beq loc_0010fe1c
    mov r0, #0
    str r0, [r6]
    add r0, r5, #19
    pop {r4, r5, r6, pc}
loc_0010fe84:
    mov r0, #0
    str r0, [r6]
    mov r0, #35
    pop {r4, r5, r6, pc}
battery_delay_clock_pointer:
    .word 0x002008a4  // 0x10fe94
battery_update_low_power:
    push {r12, lr}
    mov r1, #25
    mov r0, #21
    bl battery_test_voltage
    cmp r0, #22
    bge loc_0010feb8
    pop {r0, lr}
    b loc_0010fa24
loc_0010feb8:
    mov r1, #0
    ldr r2, [pc, #0x60]
    ldrb r3, [r2]
    cmp r3, #0
    beq loc_0010fef4
    cmp r0, #24
    ldrbge r0, [r2, #0x1]
    addge r0, r0, #1
    strbge r0, [r2, #0x1]
    strblt r1, [r2, #0x1]
    ldrb r0, [r2, #0x1]
    cmp r0, #101
    blo loc_0010ff20
    strb r1, [r2]
    b loc_0010ff1c
loc_0010fef4:
    cmp r0, #24
    ldrblt r0, [r2, #0x1]
    addlt r0, r0, #1
    strblt r0, [r2, #0x1]
    strbge r1, [r2, #0x1]
    ldrb r0, [r2, #0x1]
    cmp r0, #101
    blo loc_0010ff20
    mov r0, #1
    strb r0, [r2]
loc_0010ff1c:
    strb r1, [r2, #0x1]
loc_0010ff20:
    pop {r0, pc}
battery_low_power_state_pointer:
    .word 0x003007f1  // 0x10ff24

// Retained foreground loop for wake, queued input, LCD updates and backup entry.
main:
    push {r3, r4, r5, r6, r7, r8, r9, lr}
    ldr r4, [pc, #0x26c]
    mov r0, #84
    orr r0, r0, #28416
    str r0, [r4]
    ldr r0, [pc, #0x248]
    str r0, [r4, #0x4]
    str r0, [r4, #0x8]
    str r0, [r4, #0xc]
    bl loc_001109a0
    bl battery_update_low_power
    mov r0, #3040
    ldr r0, [r0, #-0xedc]
    lsr r0, r0, #8
    tst r0, #7
    moveq r0, #192, #18
    moveq r2, #0
    streq r2, [r0, #0x7e8]
    streq r2, [r0, #0x7ec]
    mov r0, #192, #18
    ldr r2, [r0, #0x7e8]
    ldr r3, [r0, #0x7ec]
    ldr r0, [pc, #0x208]
    cmp r3, r0
    ldreq r0, [pc, #0x204]
    cmpeq r2, r0
    movne r0, #192, #18
    blne calculator_state_init
    mov r5, #0
    strb r5, [r4, #0x10]
    mov r6, #1
    ldr r7, [pc, #0x1f8]
    ldr r8, [pc, #0x1e8]
    ldm r8, {r0, r1}
    cmp r1, #1
    cmpeq r0, #1107296256
    bne loc_0010ffc8
    mov r0, #192, #18
    bl factory_test_menu
    b loc_0011007c
loc_0010ffc8:
    cmp r1, #0
    cmpeq r0, #-1040187392
    bne loc_0011007c
    mov r0, #192, #18
    ldr r0, [r0, #0x18]
    lsl r0, r0, #20
    lsr r0, r0, #20
    cmp r0, #4
    bne loc_0011007c
    mov r0, #192, #18
    ldr r0, [r0, #0x24]
    mov r2, #5
    mov r3, #10
loc_0010fffc:
    mov r12, #15
    and r12, r12, r0, lsr #16
    .inst 0xe021c193  // Retained encoding at 0x110004
    lsl r0, r0, #4
    subs r2, r2, #1
    bne loc_0010fffc
    mov r0, #145
    orr r0, r0, #25856
    cmp r1, r0
    blo loc_0011007c
    mov r0, #184
    orr r0, r0, #136, #24
    cmp r1, r0
    bhs loc_0011007c
    str r1, [r4]
    strb r6, [r4, #0x10]
    mov r0, r7
    bl keyboard_clock_entry
    bl loc_00110c8c
    ldr r0, [pc, #0x14c]
    bl loc_00111ac0
    b loc_0011007c
loc_00110054:
    bl KeyBuffPeek
    mov r0, r7
    bl keyboard_clock_entry
    mov r0, #192, #18
    bl nut_run_and_refresh
    ldr r0, [r4, #0x8]
    bl keyboard_clock_entry
    bl battery_update_low_power
    mov r0, #80, #28
    bl loc_0010f964
loc_0011007c:
    orr r9, r6, #-1526726656
    bl KeyBuffEmpty
    cmp r0, #0
    mov r0, #44
    orr r0, r0, #192, #28
    str r9, [r0, #-0xedc]
    beq loc_00110054
    ldrb r0, [r4, #0x10]
    cmp r0, #0
    beq loc_001100ac
    bl loc_001104e4
    b loc_0011007c
loc_001100ac:
    bl loc_001116d8
    cmp r0, #0
    movne r0, #192, #18
    strbne r6, [r0, #0x42]
    blne lcd_update
    mov r0, #192, #18
    ldrb r0, [r0, #0x42]
    cmp r0, #0
    blne loc_0010fa24
    ldm r8, {r0, r1}
    cmp r1, #0
    cmpeq r0, #0
    bne loc_00110180
    mvn r0, #219
    bic r0, r0, #224, #28
    mvn r1, r5
    str r1, [r0]
    mov r0, #3056
    str r5, [r0, #-0xedc]
    mov r0, #0
    bl loc_00110e5c
    mov r0, #1
    bl loc_00110e5c
    mov r0, #2
    bl loc_00110e5c
    mov r0, #244
    orr r0, r0, #176, #28
    ldr r0, [r0, #-0xedc]
    mov r1, #-1526726656
    orr r1, r1, #128, #22
    orr r0, r1, r0
    mov r1, #244
    orr r1, r1, #176, #28
    str r0, [r1, #-0xedc]
    add r0, r1, #4
    ldr r0, [r0, #-0xedc]
    orr r0, r0, #8
    add r1, r1, #4
    str r0, [r1, #-0xedc]
    ldr r0, [r1, #-0xedc]
    bic r0, r0, #112, #24
    str r0, [r1, #-0xedc]
    ldr r0, [r1, #-0xedc]
    orr r0, r0, #1
    str r0, [r1, #-0xedc]
    orr r0, r1, #4
    mov r1, #255
    orr r1, r1, #192, #30
    str r1, [r0, #-0xedc]
    bic r0, r0, #16
    add r1, r9, #3
supc_backup_keyboard_rtc_store:
    str r1, [r0, #-0xedc]
loc_0011017c:
    b loc_0011017c
loc_00110180:
    mov r0, #2784
    str r6, [r0, #-0xedc]
    b loc_0011007c
    .word 0x001cfde0  // 0x11018c
    .word 0x12bc67d9
    .word 0xfe3954af
    .word 0x00200878
    .word 0x00111be4
    .word 0x00200898
    .word 0x02255100
lcd_wait_frames:
    ldr r1, [pc, #0x30]
    mov r2, #5
    str r2, [r1]
    str r2, [r1, #0x8]
    cmp r0, #0
    b loc_001101d0
loc_001101c0:
    ldr r2, [r1, #0xc]
    tst r2, #1
    beq loc_001101c0
    subs r0, r0, #1
loc_001101d0:
    bne loc_001101c0
    mov r0, #0
    str r0, [r1]
    bx lr
lcd_wait_irq_register_base:
    .word 0xfffb4020  // 0x1101e0

// Fixed entry for the C LCD renderer.
lcd_update:
    b mixed_lcd_entry
    .org 0x10420  // Former LCD renderer.

calculator_state_init:
    push {r4, lr}
    mov r4, r0
    mov r1, #248
    orr r1, r1, #112, #28
    bl loc_00111c88
    add r0, r4, #40
    str r0, [r4, #0x2c]
    mov r0, #1
    strb r0, [r4, #0x41]
    strb r0, [r4, #0x42]
    mov r0, #0
    strb r0, [r4, #0x43]
    ldr r2, [pc, #0x48]
    ldr r3, [pc, #0x48]
    str r2, [r4, #0x7e8]
    str r3, [r4, #0x7ec]
    strb r0, [r4, #0x7f1]
    strb r0, [r4, #0x7f2]
    ldr r0, [pc, #0x38]
    lsl r0, r0, #1
    str r0, [r4, #0x3c]
    str r0, [r4, #0x38]
    str r0, [r4, #0x34]
    str r0, [r4, #0x30]
    mov r0, r4
    bl nut_run_and_refresh
    bl KeyboardBufferClear
    mov r0, r4
    bl nut_run_and_refresh
    mov r0, r4
    pop {r4, lr}
    b lcd_update
    .word 0xfe3954af  // 0x1104a0
    .word 0x12bc67d9
    .word 0x00100100
loc_001104ac:
    push {r3, r4, r5, lr}
    mov r4, r1
    mov r5, r2
    add r0, r0, r4, lsl #8
    str r0, [sp]
    mov r2, #0
    mov r1, #3
    mov r0, sp
    bl loc_00110e00
    mov r2, #1
    mov r1, r4
    mov r0, r5
    bl loc_00110e00
    pop {r0, r4, r5, pc}
loc_001104e4:
    push {r4, lr}
    bl loc_00110d54
    mov r4, r0
    cmn r4, #1
    bne loc_00110500
    mov r0, #0
    pop {r4, pc}
loc_00110500:
    cmp r4, #40
    bge loc_00110524
    mov r0, #35
    bl loc_00110de0
    mov r0, r4
    bl AddKeyInBuffer
    mov r0, #192, #18
    bl nut_run_and_refresh
    b loc_00110568
loc_00110524:
    cmp r4, #81
    cmpne r4, #113
    bne loc_0011054c
    mov r0, #192, #18
    bl lcd_update
    ldr r2, [pc, #0x30]
    mov r1, #32
    and r0, r4, #255
loc_00110544:
    bl loc_001104ac
    b loc_00110568
loc_0011054c:
    cmp r4, #115
    ldreq r2, [pc, #0x1c]
    moveq r1, #16
    beq loc_00110544
    cmp r4, #255
    moveq r0, #15
    bleq loc_00110de0
loc_00110568:
    mov r0, #1
    pop {r4, pc}
    .word 0xfffb4200  // 0x110570
    .word 0x00111c80
display_packed_bit_routes:
    .word 0x00000006  // 0x110578
    .word 0x00000800
    .word 0x00000004
    .word 0x00000800
    .word 0x00000006
    .word 0x00000200
    .word 0x00000004
    .word 0x00000100
    .word 0x00000006
    .word 0x00001000
    .word 0x00000006
    .word 0x00002000
    .word 0x00000006
    .word 0x00000040
    .word 0x00000004
    .word 0x00000040
    .word 0x00000006
    .word 0x00000020
    .word 0x00000004
    .word 0x00000020
    .word 0x00000006
    .word 0x00000010
    .word 0x00000004
    .word 0x00000008
    .word 0x00000002
    .word 0x00000002
    .word 0x00000004
    .word 0x00000004
    .word 0x00000000
    .word 0x00000002
    .word 0x00000000
    .word 0x00000004
    .word 0x00000002
    .word 0x00000004
    .word 0x00000002
    .word 0x00000008
    .word 0x00000002
    .word 0x00000010
    .word 0x00000004
    .word 0x00000010
    .word 0x00000000
    .word 0x00000010
    .word 0x00000000
    .word 0x00000008
    .word 0x00000002
    .word 0x00000020
    .word 0x00000000
    .word 0x00000020
    .word 0x00000002
    .word 0x00000200
    .word 0x00000004
    .word 0x00000200
    .word 0x00000000
    .word 0x00000200
    .word 0x00000000
    .word 0x00000100
    .word 0x00000002
    .word 0x00000400
    .word 0x00000000
    .word 0x00000400
    .word 0x00000006
    .word 0x00000400
    .word 0x00000004
    .word 0x00000400
    .word 0x00000006
    .word 0x00000004
    .word 0x00000006
    .word 0x00000008
    .word 0x00000002
    .word 0x00000800
    .word 0x00000004
    .word 0x00001000
    .word 0x00000000
    .word 0x00000800
    .word 0x00000000
    .word 0x00001000
    .word 0x00000002
    .word 0x00001000
    .word 0x00000002
    .word 0x00002000
    .word 0x00000006
    .word 0x00000002
    .word 0x00000004
    .word 0x00000002
    .word 0x00000002
    .word 0x00000040
    .word 0x00000004
    .word 0x00000080
    .word 0x00000000
    .word 0x00000040
    .word 0x00000000
    .word 0x00000080
    .word 0x00000002
    .word 0x00000080
    .word 0x00000002
    .word 0x00000100
    .word 0x00000006
    .word 0x00000080
    .word 0x00000006
    .word 0x00000100
    .word 0x00000006
    .word 0x00010000
    .word 0x00000004
    .word 0x00010000
    .word 0x00000002
    .word 0x00004000
    .word 0x00000004
    .word 0x00004000
    .word 0x00000000
    .word 0x00004000
    .word 0x00000000
    .word 0x00002000
    .word 0x00000002
    .word 0x00008000
    .word 0x00000000
    .word 0x00008000
    .word 0x00000006
    .word 0x00004000
    .word 0x00000004
    .word 0x00002000
    .word 0x00000006
    .word 0x00008000
    .word 0x00000004
    .word 0x00008000
    .word 0x00000002
    .word 0x00010000
    .word 0x00000004
    .word 0x00020000
    .word 0x00000000
    .word 0x00010000
    .word 0x00000000
    .word 0x00020000
    .word 0x00000002
    .word 0x00020000
    .word 0x00000002
    .word 0x00040000
    .word 0x00000006
    .word 0x00020000
    .word 0x00000006
    .word 0x00040000
    .word 0x00000002
    .word 0x00080000
    .word 0x00000004
    .word 0x00080000
    .word 0x00000000
    .word 0x00080000
    .word 0x00000000
    .word 0x00040000
    .word 0x00000002
    .word 0x00100000
    .word 0x00000000
    .word 0x00100000
    .word 0x00000006
    .word 0x00200000
    .word 0x00000004
    .word 0x00200000
    .word 0x00000006
    .word 0x00400000
    .word 0x00000006
    .word 0x00800000
    .word 0x00000006
    .word 0x00100000
    .word 0x00000004
    .word 0x00100000
    .word 0x00000006
    .word 0x00080000
    .word 0x00000004
    .word 0x00040000
    .word 0x00000006
    .word 0x01000000
    .word 0x00000004
    .word 0x00800000
    .word 0x00000006
    .word 0x02000000
    .word 0x00000004
    .word 0x02000000
    .word 0x00000002
    .word 0x00200000
    .word 0x00000004
    .word 0x00400000
    .word 0x00000000
    .word 0x00200000
    .word 0x00000000
    .word 0x00400000
    .word 0x00000002
    .word 0x00400000
    .word 0x00000002
    .word 0x00800000
    .word 0x00000002
    .word 0x01000000
    .word 0x00000004
    .word 0x01000000
    .word 0x00000000
    .word 0x01000000
    .word 0x00000000
    .word 0x00800000
    .word 0x00000002
    .word 0x02000000
    .word 0x00000000
    .word 0x02000000
    push {r12, lr}
    mov r0, #0
    bl loc_001110c4
    bl keyboard_sweep_entry
    cmp r0, #0
    beq loc_001108c4
    mov r0, #0
    bl loc_00110e5c
    mov r0, #1
    bl loc_00110e5c
    b loc_00110928
loc_001108c4:
    ldr r2, [pc, #0x64]
    mov r1, #60
loc_001108cc:
    pop {r3, lr}
    b loc_00110f40
loc_001108d4:
    push {r12, lr}
    mov r0, #40
    orr r0, r0, #112, #28
    ldr r0, [r0, #-0xedc]
    bl keyboard_sweep_entry
    cmp r0, #0
    bne loc_00110928
    mov r0, #16
    mov r1, #4
    str r0, [r1, #-0xedc]
    mvn r1, #219
    bic r1, r1, #224, #28
    str r0, [r1]
    mov r0, #1824
    mov r1, #127
    orr r1, r1, #240, #26
    str r1, [r0, #-0xedc]
    ldr r2, [pc, #0x10]
    mov r1, #60
    mov r0, #0
    b loc_001108cc
loc_00110928:
    pop {r0, lr}
    b loc_00110934
    .word 0x00110898  // 0x110930
loc_00110934:
    mov r0, #16
    mov r1, #276
    str r0, [r1, #-0xff0]
    mov r1, #128
    ldr r2, [pc, #0x50]
    str r2, [r1, #-0xff0]
    mvn r1, #239
    bic r1, r1, #240, #28
    mov r2, #1
    str r2, [r1]
    mov r1, #280
    str r0, [r1, #-0xff0]
    mov r1, #52
    orr r1, r1, #128, #28
    mvn r2, #127
    bic r2, r2, #240, #26
    str r2, [r1, #-0xff0]
    mov r1, #2096
    mvn r2, r2
    str r2, [r1, #-0xff0]
    sub r1, r1, #12
    mov r2, #240, #10
    str r2, [r1, #-0xff0]
    mov r1, #68, #30
    str r0, [r1, #-0xff0]
    bx lr
    .word 0x001108d4  // 0x11099c
loc_001109a0:
    push {r12, lr}
    bl loc_00110e2c
    mov r0, #1040
    mov r1, #16
    str r1, [r0, #-0x800]
    mov r0, #240, #10
    mov r1, #96
    str r0, [r1, #-0x800]
    mov r1, #100
    mvn r2, r0
    str r2, [r1, #-0x800]
    mov r1, #127
    orr r1, r1, #240, #26
    mov r2, #20
    str r1, [r2, #-0x800]
    mvn r2, #255
    bic r2, r2, #112, #28
    str r1, [r2]
    mov r1, #52
    str r0, [r1, #-0x800]
    mov r1, #16
    str r0, [r1, #-0x800]
    str r0, [r2]
    pop {r0, lr}
    b loc_001108d4
    .zero 40
keyboard_sweep_entry:
    b keyboard_scan_entry
    .zero 380

// The original entry addresses now route to the C key ring.
KeyBuffEmpty:
    b board_queue_empty_entry
    .org 0x10bd0
KeyboardBufferClear:
    b board_queue_clear_entry
    .org 0x10be4
KeyBuffPeek:
    b board_queue_peek_entry
    .org 0x10c10
KeyBuffGetKey:
    b board_queue_get_entry
    .org 0x10c44
.global board_queue_get_return

// Stable dequeue return point used by emulator diagnostics.
board_queue_get_return:
    bx lr
AddKeyInBuffer:
    b board_queue_add_entry
    .org 0x10c8c
loc_00110c8c:
    push {r4, lr}
    mov r0, #192, #22
    mov r1, #1648
    str r0, [r1, #-0xe00]
    sub r1, r1, #108
    str r0, [r1, #-0xe00]
    mov r0, #12
    mvn r1, #0
    str r1, [r0, #-0xe00]
    mvn r4, #255
    bic r4, r4, #208, #28
    mov r0, #172
    str r0, [r4]
    ldr r0, [pc, #0x84]
    ldr r0, [r0]
    lsl r0, r0, #4
    mov r1, #64, #18
    orr r1, r1, #794624
    bl integer_signed_divide
    lsr r1, r0, #4
    and r0, r0, #15
    cmp r0, #8
    addhs r1, r1, #1
    cmp r1, #0
    moveq r1, #1
    mov r0, #32
    str r1, [r0, #-0xe00]
    mov r0, #72, #30
    add r1, r0, #226
    str r1, [r0, #-0xe00]
    mov r0, #4
    mov r1, #140, #28
    str r1, [r0, #-0xe00]
    mov r0, #64
    str r0, [r4]
    mov r0, #4
    str r0, [r4]
    mov r1, #16
    str r1, [r4]
    mov r1, #64, #30
    ldr r2, [pc, #0x1c]
    str r2, [r1, #-0xe00]
    mov r1, #260
    str r0, [r1, #-0xe00]
    mov r0, #72, #30
    mov r1, #1
    str r1, [r0, #-0xe00]
    pop {r4, pc}
    .word 0x002008a4  // 0x110d4c
    .word 0x00200894
loc_00110d54:
    mvn r0, #223
    bic r0, r0, #208, #28
    ldr r0, [r0]
    cmp r0, #0
    bne loc_00110d6c
loc_00110d68:
    b loc_00110dd8
loc_00110d6c:
    ldr r1, [pc, #0xe4]
    mov r0, #224
    ldr r0, [r0, #-0xde0]
    add r2, r1, #28
    cmp r0, r2
    beq loc_00110d68
    mov r0, #64, #30
    mov r2, #2
    str r2, [r0, #-0xde0]
    ldr r2, [r1, #0x1c]
    and r0, r2, #255
    lsr r2, r2, #8
    str r2, [r1, #0x1c]
    mov r1, #224
    ldr r1, [r1, #-0xde0]
    sub r1, r1, #1
    mov r2, #224
    str r1, [r2, #-0xde0]
    mov r1, #228
    ldr r1, [r1, #-0xde0]
    add r1, r1, #1
    mov r2, #228
    str r1, [r2, #-0xde0]
    mov r1, #64, #30
    mov r2, #1
    str r2, [r1, #-0xde0]
    bx lr
loc_00110dd8:
    mvn r0, #0
    bx lr
loc_00110de0:
    mvn r1, #235
    bic r1, r1, #208, #28
    ldr r1, [r1]
    tst r1, #2
    beq loc_00110de0
    mov r1, #8
    str r0, [r1, #-0xdec]
    bx lr
loc_00110e00:
    push {r3, r4, r5, lr}
    mov r5, r0
    mov r4, r1
    b loc_00110e18
loc_00110e10:
    ldrb r0, [r5], #1
    bl loc_00110de0
loc_00110e18:
    mov r0, r4
    sub r4, r0, #1
    cmp r0, #0
    bne loc_00110e10
    pop {r0, r4, r5, pc}
loc_00110e2c:
    ldr r0, [pc, #0x24]
    mov r2, #0
    mov r3, #0
    stm r0, {r2, r3}
    mov r1, #0
    strb r1, [r0, #0xb]
    strb r1, [r0, #0xa]
    mvn r2, r1
    strb r2, [r0, #0x8]
    strb r1, [r0, #0x9]
    bx lr
    .word 0x00200878  // 0x110e58
loc_00110e5c:
    push {r4, lr}
    mov r4, r0
    bl loc_00110fe0
    mov r0, #1
    add r1, r4, #12
    lsl r0, r0, r1
    mvn r1, #235
    bic r1, r1, #192, #30
    str r0, [r1]
    pop {r4, pc}
loc_00110e84:
    push {r3, r4, r5, r6, r7, lr}
    ldr r12, [pc, #0xac]
    ldr r4, [r12]
    asr r5, r4, #31
    .inst 0xe0876490  // Retained encoding at 0x110e94
    .inst 0xe0277590  // Retained encoding at 0x110e98
    .inst 0xe0277491  // Retained encoding at 0x110e9c
    lsr r6, r6, #21
    orr r6, r6, r7, lsl #11
    str r6, [r3]
    mov r0, #0
    str r0, [r2]
    ldr r0, [r3]
    cmp r0, #64, #22
    blo loc_00110f38
    lsr r0, r0, #2
    str r0, [r3]
    mov r0, #1
    str r0, [r2]
    ldr r0, [r3]
    cmp r0, #64, #22
    blo loc_00110f38
    lsr r0, r0, #2
    str r0, [r3]
    mov r0, #2
    str r0, [r2]
    ldr r0, [r3]
    cmp r0, #64, #22
    blo loc_00110f38
    lsr r0, r0, #2
    str r0, [r3]
    mov r0, #3
    str r0, [r2]
    ldr r0, [r3]
    cmp r0, #64, #22
    blo loc_00110f38
    lsr r0, r0, #3
    str r0, [r3]
    mov r0, #4
    str r0, [r2]
    ldr r0, [r3]
    cmp r0, #64, #22
    movhs r0, #255
    orrhs r0, r0, #65280
    strhs r0, [r3]
loc_00110f38:
    pop {r0, r4, r5, r6, r7, pc}
    .word 0x002008a4  // 0x110f3c
loc_00110f40:
    b keyboard_schedule
    mov r8, r2
    lsl r2, r0, #6
    sub r4, r2, #96, #20
    add r5, r0, #12
    mov r7, #1
    lsl r6, r7, r5
    mov r0, #2800
    str r6, [r0, #-0xee0]
    mov r0, #2
    str r0, [r4]
    rsb r0, r7, #0
    str r0, [r4, #0x28]
    ldr r0, [r4, #0x20]
    mov r3, sp
    add r2, sp, #4
    lsl r0, r1, #10
    asr r1, r0, #31
    bl loc_00110e84
    ldr r0, [sp, #0x4]
    orr r0, r0, #192, #24
    str r0, [r4, #0x4]
    ldr r0, [sp]
    str r0, [r4, #0x1c]
    mov r0, #4
    str r6, [r0, #-0xee0]
    lsl r0, r5, #2
    str r8, [r0, #-0xf80]
    sub r0, r0, #64, #26
    str r7, [r0]
    mov r0, #8
    str r6, [r0, #-0xee0]
    mov r0, #16
    str r0, [r4, #0x24]
    mvn r0, #223
    bic r0, r0, #224, #28
    str r6, [r0]
    mov r0, #5
    str r0, [r4]
    pop {r0, r1, r4, r5, r6, r7, r8, pc}
loc_00110fe0:
    mov r1, #1
    add r0, r0, #12
    lsl r0, r1, r0
    mov r1, #4
    str r0, [r1, #-0xedc]
    mvn r1, #219
    bic r1, r1, #224, #28
    str r0, [r1]
    bx lr
loc_00111004:
    push {r2, r3, r4, r5, r7, lr}
    mov r4, r0
    mov r12, r1
    ldr r0, [r4, #0x20]
    tst r0, #64, #22
    beq loc_0011107c
    ldr lr, [r4, #0x10]
    ldr r0, [r4, #0x4]
    and r0, r0, #7
    ldr r1, [pc, #0x50]
    ldr r7, [r1, r0, lsl #2]
    add r5, sp, #4
    .inst 0xe081079e  // Retained encoding at 0x111034
    lsl r1, r1, #20
    orr r1, r1, r0, lsr #12
    lsl r0, r0, #20
    mov r2, r12
    asr r3, r12, #31
    bl loc_0011155c
    mov r3, sp
    mov r2, r5
    bl loc_00110e84
    ldr r0, [r4, #0x4]
    lsr r0, r0, #3
    ldr r1, [sp, #0x4]
    orr r0, r1, r0, lsl #3
    str r0, [r4, #0x4]
    ldr r0, [pc, #0xc]
    ldr r1, [sp]
    str r1, [r0]
loc_0011107c:
    pop {r0, r1, r4, r5, r7, pc}
    .word 0x00111c5c  // 0x111080
    .word 0xfffa001c
loc_00111088:
    push {r3, r4, r5, lr}
    mov r4, r0
    mov r1, r4
    mov r0, #-16777216
    orr r0, r0, #16384000
    bl loc_00111004
    mov r5, #-16777216
    orr r5, r5, #16384000
    mov r1, r4
    add r0, r5, #64
    bl loc_00111004
    mov r1, r4
    add r0, r5, #128
    pop {r2, r4, r5, lr}
    b loc_00111004
loc_001110c4:
    lsl r0, r0, #6
    sub r0, r0, #96, #20
    ldr r0, [r0, #0x20]
    and r0, r0, #1
    bx lr
integer_signed_divide:
    ands r2, r1, #128, #8
    rsbmi r1, r1, #0
    eors r2, r2, r0, asr #32
    bne loc_0011128c
loc_001110e8:
    cmp r0, r1
    cmphs r1, #2
    blo loc_00111158
    mov r3, #0
    cmp r1, r0, lsr #16
    lslls r1, r1, #16
    addls r3, r3, #16
    cmp r1, r0, lsr #8
    lslls r1, r1, #8
    addls r3, r3, #8
    cmp r1, r0, lsr #4
    lslls r1, r1, #4
    addls r3, r3, #4
    cmp r1, r0, lsr #2
    lslls r1, r1, #2
    addls r3, r3, #2
    cmp r1, r0, lsr #1
    lslls r1, r1, #1
    addls r3, r3, #1
    subs r0, r0, r1
    lsr r1, r1, #1
    rsb r1, r1, #0
    sbcs r3, r3, #1
    ble loc_00111274
    adds r0, r0, r1
    sublo r0, r0, r1
    rsb r12, r3, #32
    add pc, pc, r12, lsl #3
loc_00111158:
    tst r1, r1
    beq loc_00111c90
    cmp r0, r1
    movlo r1, r0
    movlo r0, #0
    movhs r1, #0
    bx lr
integer_division_unrolled:
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    adcs r0, r1, r0, lsl #1
    sublo r0, r0, r1
    lsr r1, r0, r3
    eor r0, r0, r1, lsl r3
    adc r0, r0, r0
    mov r12, #2
    orr r0, r0, r12, lsl r3
    bx lr
loc_00111274:
    adds r3, r3, #1
    addslo r0, r0, r1
    sublo r0, r0, r1
    mov r1, r0
    adc r0, r3, r3
    bx lr
loc_0011128c:
    push {r2, lr}
    rsbhs r0, r0, #0
    bl loc_001110e8
    lsls r2, r2, #1
    rsbmi r1, r1, #0
    rsbhs r0, r0, #0
    pop {r2, lr}
    bx lr
display_segment_identifiers:
    .word 0x00000003  // 0x1112ac
    .word 0x0000001e
    .word 0x00000037
    .word 0x00000036
    .word 0x0000001c
    .word 0x00000002
    .word 0x0000001d
    .word 0x00000052
    .word 0x00000051
    .word 0x00000004
    .word 0x00000006
    .word 0x00000039
    .word 0x00000038
    .word 0x0000001f
    .word 0x00000005
    .word 0x00000020
    .word 0x0000003a
    .word 0x00000054
    .word 0x00000008
    .word 0x00000023
    .word 0x0000003c
    .word 0x0000003b
    .word 0x00000021
    .word 0x00000007
    .word 0x00000022
    .word 0x00000057
    .word 0x00000056
    .word 0x00000009
    .word 0x0000000b
    .word 0x0000003e
    .word 0x0000003d
    .word 0x00000024
    .word 0x0000000a
    .word 0x00000025
    .word 0x0000003f
    .word 0x00000059
    .word 0x0000000d
    .word 0x00000028
    .word 0x00000041
    .word 0x00000040
    .word 0x00000026
    .word 0x0000000c
    .word 0x00000027
    .word 0x0000005c
    .word 0x0000005b
    .word 0x0000000e
    .word 0x00000010
    .word 0x00000043
    .word 0x00000042
    .word 0x00000029
    .word 0x0000000f
    .word 0x0000002a
    .word 0x00000044
    .word 0x0000005e
    .word 0x00000012
    .word 0x0000002d
    .word 0x00000046
    .word 0x00000045
    .word 0x0000002b
    .word 0x00000011
    .word 0x0000002c
    .word 0x00000061
    .word 0x00000060
    .word 0x00000013
    .word 0x00000015
    .word 0x00000048
    .word 0x00000047
    .word 0x0000002e
    .word 0x00000014
    .word 0x0000002f
    .word 0x00000049
    .word 0x00000063
    .word 0x00000017
    .word 0x00000032
    .word 0x0000004b
    .word 0x0000004a
    .word 0x00000030
    .word 0x00000016
    .word 0x00000031
    .word 0x00000066
    .word 0x00000065
    .word 0x00000018
    .word 0x0000001a
    .word 0x0000004d
    .word 0x0000004c
    .word 0x00000033
    .word 0x00000019
    .word 0x00000034
    .word 0x0000004e
    .word 0x00000068
Lcd_Init:
    ldr r0, [pc, #0x7c]
    ldr r1, [r0, #0x10]
    cmp r1, #1
    beq loc_00111450
    mov r1, #8
    str r1, [r0]
    ldr r1, [pc, #0x20]
    str r1, [r0, #0x4]
    mov r1, #2
    str r1, [r0, #0x8]
    mov r1, #1
    str r1, [r0]
loc_00111444:
    ldr r1, [r0, #0x10]
    cmp r1, #1
    bne loc_00111444
loc_00111450:
    bx lr
    .word 0x00201903  // 0x111454
Lcd_Disable:
    ldr r0, [pc, #0x38]
    mov r1, #2
    str r1, [r0]
    mvn r0, #231
    bic r0, r0, #128, #30
    ldr r0, [r0]
    bic r0, r0, #48
    orr r0, r0, #-1526726656
    mvn r1, #231
    bic r1, r1, #128, #30
    str r0, [r1]
loc_00111484:
    mov r0, #12
    ldr r0, [r0, #-0x2e8]
    tst r0, #64, #30
    bne loc_00111484
    bx lr
    .word 0xfffb4000  // 0x111498

// Fixed entry for the C contrast register update.
Lcd_SetContrast:
    b board_contrast_entry
    .org 0x114c8
LCDMODE_Select:
    mvn r1, #231
    bic r1, r1, #128, #30
    ldr r1, [r1]
    bic r1, r1, #48
    orr r1, r0, r1
    orr r1, r1, #-1526726656
    mvn r2, #231
    bic r2, r2, #128, #30
    str r1, [r2]
    cmp r0, #0
    cmpne r0, #16
    bne loc_001114fc
    b loc_00111484
loc_001114fc:
    mov r0, #12
    ldr r0, [r0, #-0x2e8]
    tst r0, #64, #30
    beq loc_001114fc
    bx lr
Lcd_Enable:
    push {r4, lr}
    mov r4, r0
    mov r0, #48
    bl LCDMODE_Select
    mov r2, #80
    mov r1, #0
    ldr r0, [pc, #0x10]
    bl compiler_fill_length_first
    bl Lcd_Init
    mov r0, r4
    pop {r4, lr}
    b Lcd_SetContrast
    .word 0xfffb4200  // 0x111540
    .word 0xe213c480
    .word 0x5a000001
    .word 0xe2722000
    .word 0xe2e33000
    .word 0xe03cc041
    .word 0x1a00000e
loc_0011155c:
    orrs r12, r3, r1
    bne loc_001115d4
    push {r12, lr}
    mov r1, r2
    bl loc_001110e8
    mov r2, r1
    mov r1, #0
    mov r3, #0
    pop {r12, lr}
    bx lr
loc_00111584:
    mov r3, r1
    mov r2, r0
    mov r1, #0
    mov r0, #0
    bx lr
    push {r12, lr}
    blo loc_001115a8
    rsbs r0, r0, #0
    rsc r1, r1, #0
loc_001115a8:
    bl loc_0011155c
    pop {r12, lr}
    lsls r12, r12, #1
    blo loc_001115c4
    rsbs r0, r0, #0
    rsc r1, r1, #0
    tst r12, r12
loc_001115c4:
    bxpl lr
    rsbs r2, r2, #0
    rsc r3, r3, #0
    bx lr
loc_001115d4:
    cmp r0, r2
    sbcs r12, r1, r3
    blo loc_00111584
    orrs r12, r2, r3
    beq loc_00111c94
    push {r4, r5}
    mov r12, #0
loc_001115f0:
    adds r2, r2, r2
    adcs r3, r3, r3
    bhs loc_0011160c
    cmp r1, r3
    cmpeq r0, r2
    addhs r12, r12, #1
    bhs loc_001115f0
loc_0011160c:
    rrxs r3, r3
    rrx r2, r2
    mov r5, #128, #8
    subs r4, r12, #32
    lsrhs r4, r5, r4
    movhs r5, #0
    lsrlo r5, r5, r12
    movlo r4, #0
    b loc_00111638
loc_00111630:
    lsrs r3, r3, #1
    rrx r2, r2
loc_00111638:
    cmp r0, r2
    sbcs r12, r1, r3
    subhs r0, r0, r2
    movhs r1, r12
    adcs r4, r4, r4
    adcs r5, r5, r5
    blo loc_00111630
    mov r2, r0
    mov r3, r1
    mov r0, r4
    mov r1, r5
    pop {r4, r5}
    bx lr
loc_0011166c:
    mvn r0, #231
    bic r0, r0, #128, #30
    ldr r0, [r0]
    mov r1, #164, #8
    orr r1, r1, #17039360
    orr r0, r1, r0
    mvn r1, #231
    bic r1, r1, #128, #30
    str r0, [r1]
loc_00111690:
    mov r0, #12
    ldr r0, [r0, #-0x2e8]
    tst r0, #64, #28
    beq loc_00111690
    mov r0, #72
    ldr r0, [r0, #-0x2e8]
    bic r0, r0, #3
    mov r1, #72
    str r0, [r1, #-0x2e8]
    mov r0, #76
    mov r1, #0
    str r1, [r0, #-0x2e8]
    mov r0, #127
    mov r1, #100
    str r0, [r1, #-0x2e8]
    mov r1, #108
    str r0, [r1, #-0x2e8]
    bx lr
loc_001116d8:
    mvn r0, #135
    bic r0, r0, #128, #30
    ldr r0, [r0]
    tst r0, #2
    movne r0, #1
    moveq r0, #0
    mov r1, #127
    mov r2, #4
    str r1, [r2, #-0x288]
    mov r2, #12
    str r1, [r2, #-0x288]
    bx lr
loc_00111708:
    mvn r0, #231
    bic r0, r0, #128, #30
    ldr r0, [r0]
    bic r0, r0, #64, #20
    orr r0, r0, #-1526726656
    mvn r1, #231
    bic r1, r1, #128, #30
    str r0, [r1]
loc_00111728:
    mov r0, #12
    ldr r0, [r0, #-0x2e8]
    tst r0, #64, #28
    bne loc_00111728
    bx lr
loc_0011173c:
    mov r12, #32512
    and r1, r12, r1, lsl #8
    orr r0, r1, r0
    mov r1, #252, #18
    and r1, r1, r2, lsl #16
    orr r0, r1, r0
    orr r0, r3, r0
    mvn r1, #143
    bic r1, r1, #128, #30
    str r0, [r1]
    bx lr
loc_00111768:
    mvn r0, #151
    bic r0, r0, #128, #30
    ldr r0, [r0]
    mvn r1, #151
    bic r1, r1, #128, #30
    ldr r1, [r1]
    cmp r0, r1
    bne loc_00111768
    bx lr
cpureset:
    mvn r0, #255
    bic r0, r0, #128, #30
    mov r1, #13
    orr r1, r1, #-1526726656
    str r1, [r0]
    bx lr
LowLevelInit:
    sub sp, sp, #8
    mov r0, #1
    mov r1, #2992
    str r0, [r1, #-0xf80]
loc_001117b4:
    mov r1, #232
    orr r1, r1, #176, #28
    ldr r1, [r1, #-0xf80]
    tst r1, #8
    beq loc_001117b4
    mov r1, #2992
    ldr r2, [r1, #-0xf80]
    str r2, [r1, #-0xf80]
loc_001117d4:
    mov r1, #232
    orr r1, r1, #176, #28
    ldr r1, [r1, #-0xf80]
    tst r1, #8
    beq loc_001117d4
    mov r1, #212
    orr r1, r1, #192, #28
    mvn r2, #224, #8
    bic r2, r2, #56832
    str r2, [r1, #-0xf80]
    mov r1, #164
    rsb r2, r0, #0
    str r2, [r1, #-0xf80]
    ldr r1, [pc, #0x78]
    mvn r2, #127
    bic r2, r2, #240, #28
    str r1, [r2]
    str r0, [sp]
    b loc_00111838
loc_00111820:
    ldr r2, [sp]
    lsl r2, r2, #2
    str r1, [r2, #-0xf80]
    ldr r2, [sp]
    add r2, r2, #1
    str r2, [sp]
loc_00111838:
    ldr r2, [sp]
    cmp r2, #31
    blo loc_00111820
    mov r2, #180
    str r1, [r2, #-0xf80]
    mov r2, #0
    str r2, [sp]
    b loc_0011186c
loc_00111858:
    mov r1, #176
    str r2, [r1, #-0xf80]
    ldr r1, [sp]
    add r1, r1, #1
    str r1, [sp]
loc_0011186c:
    ldr r1, [sp]
    cmp r1, #8
    blo loc_00111858
    mov r1, #184
    str r0, [r1, #-0xf80]
    add sp, sp, #8
    bx lr
    .word 0x0011178c  // 0x111888
    .org 0x11944  // C owns Nut decimal arithmetic.

// Instruction-count delay shared by the scanner strobes and Nut waits.
software_wait:
    subs r0, r0, #1
    bne software_wait
    bx lr
    .org 0x11a64  // Former masked arithmetic helpers.

    .word 0x20682043  // 0x111a64
    .word 0x202d2045
    .word 0x202d202d
    .word 0x2020202d
    .word 0x20682020
    .word 0x00000000
version_template:
    .ascii "2 0 2 6 - 1 1 - 2 2 "
    .zero 4
    .word 0x33323130  // 0x111a94
    .word 0x37363534
    .word 0x42413839
    .word 0x46454443
    .word 0x00000000
    .word 0x20432020
    .word 0x20322020
    .word 0x20302030
    .word 0x20202038
    .word 0x20702068
    .word 0x00000000
loc_00111ac0:
    b loc_00111ae4
loc_00111ac4:
    mvn r1, #235
    bic r1, r1, #208, #28
    ldr r1, [r1]
    tst r1, #2
    beq loc_00111ac4
    mov r1, #8
    ldrb r2, [r0], #1
    str r2, [r1, #-0xdec]
loc_00111ae4:
    ldrb r1, [r0]
    cmp r1, #0
    bne loc_00111ac4
    b loc_00111af4
loc_00111af4:
    mvn r0, #235
    bic r0, r0, #208, #28
    ldr r0, [r0]
    tst r0, #2
    beq loc_00111af4
    bx lr
compiler_fill_length_first:
    lsls r2, r2, #24
    orr r2, r2, r2, lsr #8
    orr r2, r2, r2, lsr #16
loc_00111b18:
    push {r2, lr}
    mov r3, r2
    mov lr, r2
    mov r12, r2
loc_00111b28:
    subs r1, r1, #16
    stmhs r0!, {r2, r3, r12, lr}
    bhi loc_00111b28
    lsls r12, r1, #29
    stmhs r0!, {r2, r3}
    strmi r2, [r0], #4
    lsls r1, r1, #31
    strhhs r2, [r0], #2
    strbmi r2, [r0], #1
    pop {r2, lr}
    bx lr
case64_relative_dispatch:
    push {r4, r5}
    bic lr, lr, #1
loc_00111b5c:
    ldm lr!, {r4, r5, r12}
    cmp r0, r4
    cmpeq r1, r5
    beq loc_00111b78
    subs r2, r2, #1
    bne loc_00111b5c
    ldr r12, [lr], #4
loc_00111b78:
    pop {r4, r5}
    add lr, lr, r12
    bx lr

// The C interpreter indexes these bytes by physical key number.
physical_key_to_nut:
    .word 0xc3733313  // 0x111b84
    .word 0x72c28283
    .word 0x30101232
    .word 0x8780c070
    .word 0x173777c7
    .word 0xc1713111
    .word 0x74c48481
    .word 0x38181434
    .word 0x0088c878
    .word 0x153575c5
    mov r1, #0
    b loc_00111bc4
loc_00111bb4:
    ldr r2, [r0], #4
loc_00111bb8:
    subs r3, r3, #4
    str r1, [r2], #4
    bne loc_00111bb8
loc_00111bc4:
    ldr r3, [r0], #4
    cmp r3, #0
    bne loc_00111bb4
    bx lr

// Retained zero-init descriptor. No current caller has been identified.
compiler_zero_descriptor:
    .word 0x00111bac  // 0x111bd4
    .word 0x00000014
    .word 0x00200000
    .word 0x00000000
    .word 0x20555043
    .word 0x65657053
    .word 0x65732064
    .word 0x54202c74
    .word 0x20747365
    .word 0x74737973
    .word 0x4f206d65
    .word 0x000a0d4e
compiler_u64_shift_left_byte_count:
    and r2, r2, #255
    subs r12, r2, #32
    lslhs r1, r0, r12
    lsllo r1, r1, r2
    rsblo r12, r2, #32
    orrlo r1, r1, r0, lsr r12
    lsl r0, r0, r2
    bx lr
    and r2, r2, #255
    subs r12, r2, #32
    lsrhs r0, r1, r12
    lsrlo r0, r0, r2
    rsblo r12, r2, #32
    orrlo r0, r0, r1, lsl r12
    lsr r1, r1, r2
    bx lr
    .word 0x204c2e31
    .word 0x20432e32
    .word 0x20482e33
    .word 0x20502e34
    .word 0x20202020
    .word 0x00000000
    .word 0x00000002  // 0x111c5c
    .word 0x00000008
    .word 0x00000020
    .word 0x00000080
    .word 0x00000400

// The C RAM handler has its own map. These original words are retained in place.
nut_ram_page_map:
    .word 0x02010100  // 0x111c70
    .word 0x06050403
    .word 0x0a090807
    .word 0x0e0d0c0b
// The factory formatter reads 11/22/2026 as packed BCD across these words.
factory_version_bcd:
    .word 0x60000001, 0x71122202
loc_00111c88:
    movs r2, #0
    b loc_00111b18
loc_00111c90:
    bx lr
loc_00111c94:
    bx lr
stored_image_checksum:
    .byte 0  // The image writer fills this checksum byte.
    .byte 0, 0, 0
firmware_end:
