/* P/Q operations and cached fields recovered from HP-15C LE ARM firmware. */
#ifndef LE_NUT_POINTER_H
#define LE_NUT_POINTER_H
#include "le_recovered.h"

/* Rebuild cached shifts and field masks using the selected digit. */
void le_nut_refresh_fields(LeNutState *state, unsigned selected);

/* Supported opcodes return 0. Unsupported returns -1; invalid P/Q or selected
 * ARM address returns -2. Errors leave state/output unchanged. P/Q must be
 * 0..13 and selected_pointer must be LE_BACKUP_BASE+0x28 or +0x29.
 * The output is the native next-pointer result, including the peculiar 120
 * handler's bare boolean. No correction of native behavior is performed. */
int le_nut_pointer_execute(LeNutState *state, unsigned opcode,
                          uint32_t next_pointer, uint32_t *result_pointer);
#endif
