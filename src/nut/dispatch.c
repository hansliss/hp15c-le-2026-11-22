#include "firmware_bridge.h"

#define WORD(address) (*(volatile uint32_t *)(uintptr_t)(address))

enum Handler {
    ARITHMETIC, COMPARE, CONTROL, FIELD, FLOW, KEYBOARD, MISC, PLATFORM,
    POINTER, RAM, TRANSFER,
};

static const uint8_t handler_for_opcode[1024] = {
#include "dispatch_table.inc"
};

static unsigned keys_held(void)
{
    uint64_t bitmap;
    const uintptr_t address = 0x200878;
    /* Take both words in one instruction, as the native handler did.
     * A scanner interrupt can move activity between words. */
    __asm__ volatile("ldmia %1, {%Q0, %R0}" : "=&r"(bitmap) : "r"(address) : "memory");
    return bitmap != 0;
}

static unsigned queue_empty(void)
{
    return ((unsigned (*)(void))(uintptr_t)0x110bac)();
}

static unsigned read_key_code(void)
{
    unsigned index = ((unsigned (*)(void))(uintptr_t)0x110c10)();
    return *(const uint8_t *)(uintptr_t)(0x111b84u + index);
}

static void set_clock(uint32_t speed)
{
    ((void (*)(uint32_t))(uintptr_t)0x10fb7c)(speed);
}

static void wait_cycles(uint32_t count)
{
    ((void (*)(uint32_t))(uintptr_t)0x111944)(count);
}

/* Adapt the physical key queue and release waits to Nut opcodes. */
static uint32_t execute_keyboard(LeNutState *state, unsigned opcode, uint32_t next)
{
    uint32_t pc = (next - LE_ROM_BASE - 2u) >> 1;

    switch (opcode) {
    case 0x118:
        state->display_blink = 0;
        le_mixed_display_request(state);
        set_clock(WORD(0x2008a0));
        for (unsigned i = 0; i < 128 && keys_held(); ++i)
            wait_cycles((uint32_t)((int32_t)WORD(0x20089c) / 512));
        set_clock(0x02255100u);
        state->c = (state->c & ~UINT64_C(0xfff)) | 1u;
        return next;
    case 0x1dc: {
        set_clock(WORD(0x2008a0));
        unsigned count = (state->c >> 4) & 0xffu;
        state->c = (state->c & ~UINT64_C(0xfff)) | 0x37u;
        while (count--) {
            uint32_t scaled = WORD(0x2008a4) * 10u;
            wait_cycles((uint32_t)((int32_t)scaled / 4096));
            if (!keys_held())
                return next;
        }
        state->c &= ~UINT64_C(0xfff);
        return next + 1;
    }
    case 0x220: {
        unsigned key = queue_empty() ? 0 : read_key_code();
        state->c = (state->c & ~UINT64_C(0xff000)) | (key << 12);
        return next;
    }
    case 0x230:
        return (LE_ROM_BASE + 2 * (pc & (0xff00u + read_key_code()))) * 2;
    case 0x3cc:
        return next + ((pc == 0x13be || pc == 0x13d0 || pc == 0x16ee)
                       ? keys_held() : !queue_empty());
    case 0x3c8:
        return next;
    }
    return next;
}

uint32_t le_mixed_dispatch(LeNutState *state, uint32_t offset)
{
    uint32_t pointer = LE_ROM_BASE + offset;
    for (;;) {
        uint32_t carry = pointer & 1u;
        uint32_t address = pointer & ~1u;
        unsigned opcode = *(const uint16_t *)(uintptr_t)address;
        pointer = address + 2;
        switch (handler_for_opcode[opcode]) {
        case ARITHMETIC:
            pointer = le_mixed_arithmetic_execute(state, opcode, pointer);
            break;
        case COMPARE:
            pointer = le_mixed_compare_execute(state, opcode, pointer);
            break;
        case CONTROL:
            pointer = le_mixed_control_execute(state, opcode, pointer);
            break;
        case FIELD:
            pointer = le_mixed_field_execute(state, opcode, pointer);
            break;
        case FLOW:
            pointer = le_mixed_flow_execute(state, opcode, pointer, carry);
            break;
        case KEYBOARD:
            pointer = execute_keyboard(state, opcode, pointer);
            break;
        case MISC:
            pointer = le_mixed_misc_execute(state, opcode, pointer);
            break;
        case PLATFORM: {
            uint64_t result = le_mixed_platform_execute(state, opcode, pointer);
            pointer = (uint32_t)result;
            if (result >> 32)
                return pointer;
            break;
        }
        case POINTER:
            pointer = le_mixed_pointer_execute(state, opcode, pointer);
            break;
        case RAM:
            le_mixed_ram_execute(state, opcode);
            break;
        case TRANSFER:
            pointer = le_mixed_transfer_execute(state, opcode, pointer);
            break;
        }
    }
}
