/* Nut RAM paths recovered from the supplied HP-15C LE firmware. */
#ifndef LE_NUT_RAM_H
#define LE_NUT_RAM_H

#include "le_recovered.h"

typedef enum {
    LE_NUT_RAM_APRIL = 0,
    LE_NUT_RAM_2009 = 1
} LeNutRamVariant;

/* Direct display notification, outside the optional display-opcode quota.
 * It may update calculator state; the write precedes this synchronous call.
 */
typedef void (*LeNutRamDisplay)(void *context, LeNutState *state);

/* Execute the RAM/select subset: immediate page/register selection, reads,
 * writes, selected-register write and page clear. No ROM pointer/carry effects.
 * Returns 0 on success, -1 for unsupported opcode, -2 for invalid selectors.
 * The latter guards corrupt inputs; the original ARM has no equivalent bound
 * check. Supported firmware selectors are mapped page 0..14/register 0..15.
 * Display must be valid when the selected path can request rendering.
 * All 64 value bits are preserved, including diagnostic upper eight bits.
 */
int le_nut_ram_execute(LeNutRamVariant variant, LeNutState *state, unsigned opcode,
                       LeNutRamDisplay display, void *context);

#endif
