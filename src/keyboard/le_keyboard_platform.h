#ifndef LE_KEYBOARD_PLATFORM_H
#define LE_KEYBOARD_PLATFORM_H
#include "le_keyboard_scan.h"

/* Main stack ends here. Native IRQ storage starts at 0x200814. */
#define LE_KEYBOARD_RUNTIME_ADDRESS UINT32_C(0x2007c4)
#define LE_KEYBOARD_STACK_BOTTOM UINT32_C(0x200014)
#define LE_KEYBOARD_STACK_GUARD UINT32_C(0x47554135)
typedef struct {
    LeKeyboardScan scan;
    uint32_t context;
    uint32_t reserved[3];
} LeKeyboardRuntime;
_Static_assert(sizeof(LeKeyboardRuntime)==80,"Keyboard runtime allocation");
_Static_assert(LE_KEYBOARD_RUNTIME_ADDRESS+sizeof(LeKeyboardRuntime)==0x200814,"Native IRQ boundary");

/* Restore a validated warm-boot profile or initialize the default scanner. */
void keyboard_boot(void);
/* Sweep the matrix, enqueue newly pressed keys, and return one when idle. */
unsigned keyboard_candidate_scan(void);
/* Supply the active profile interval to the native timer-0 adapter. */
unsigned keyboard_timer_units(void);
/* Run the factory diagnostics and tuning menu, then restore calculator mode. */
void keyboard_factory_menu(void *calc);
#endif
