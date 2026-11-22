/* Layout recovered from HP15C+ 04-15-11, not a complete emulator. */
#ifndef LE_RECOVERED_H
#define LE_RECOVERED_H
#include <stddef.h>
#include <stdint.h>

#define LE_ROM_BASE   UINT32_C(0x00100100)
#define LE_BACKUP_BASE UINT32_C(0x00300000)

/* All pointers below are ARM addresses, deliberately not host pointers.
 * Names for RAM/page/scratch fields remain provisional; see RESEARCH.md.
 * uint64_t stores 14 packed nibbles, little endian, low nibble = digit zero.
 */
typedef struct {
    uint64_t a, b, c, n, m;                  /* 00..27 */
    uint8_t p, q, g, reserved_2b;            /* 28..2b */
    uint32_t selected_pointer;              /* 2c: &p or &q on ARM */
    uint32_t return_pointer[4];             /* 30..3f */
    uint8_t return_index, hex_mode;         /* 40,41 */
    uint8_t display_off, display_blink;     /* 42: 1=off, 0=enabled; 43: blink */
    uint16_t status;                        /* 44 */
    uint8_t ram_page, ram_register;         /* 46,47 */
    uint8_t selected_digit_shift, p_digit_shift; /* 48,49: selected digit*4, P*4 */
    uint8_t unknown_4a[6];
    uint64_t selected_digit_mask, through_selected_mask, pq_mask; /* 50: selected digit; 58: 0..selected; 60: P..Q, or P..13 when Q<P */
    uint64_t ram_candidate[240];            /* 68..7e7: inferred extent */
    uint64_t reset_marker;                  /* 7e8: 12bc67d9fe3954af */
    uint8_t trailing_state[8];              /* 7f0..7f7: not fully mapped */
} LeNutState;

_Static_assert(offsetof(LeNutState, n) == 0x18, "N register layout");
_Static_assert(offsetof(LeNutState, m) == 0x20, "M register layout");
_Static_assert(offsetof(LeNutState, selected_pointer) == 0x2c, "ARM pointer layout");
_Static_assert(offsetof(LeNutState, display_off) == 0x42, "active-low display flag layout");
_Static_assert(offsetof(LeNutState, status) == 0x44, "status layout");
_Static_assert(offsetof(LeNutState, selected_digit_mask) == 0x50, "field masks layout");
_Static_assert(offsetof(LeNutState, ram_candidate) == 0x68, "RAM layout");
_Static_assert(offsetof(LeNutState, reset_marker) == 0x7e8, "reset marker layout");
_Static_assert(sizeof(LeNutState) == 0x7f8, "backup state size");

#endif
