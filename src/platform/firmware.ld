ENTRY(firmware_start)
SECTIONS
{
    .firmware 0x00100000 : { KEEP(*(.firmware)) }
    .payload 0x00111ca0 : {
        mixed_payload_start = .;
        *(.text.mixed_entry)
        *(.text*)
        *(.rodata*)
        mixed_payload_end = .;
    }
    ASSERT(mixed_payload_end <= 0x0011f000, "C payload exceeds application flash")
    .image_end 0x0011ffff : { BYTE(0) }
    .data 0x00200014 : { *(.data*) }
    .bss : { *(.bss*) *(COMMON) }
    ASSERT(SIZEOF(.data) == 0, "Mixed build introduced initialized SRAM")
    ASSERT(SIZEOF(.bss) == 0, "Mixed build introduced fixed SRAM allocation")
    /DISCARD/ : { *(.ARM.exidx*) *(.ARM.extab*) *(.comment) *(.note*) *(.llvm_addrsig) }
}
