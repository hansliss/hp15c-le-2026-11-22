/* Native RAM opcode bridge: state layout and selectors match the April LE.
 * Display notifications remain synchronous and outside the opcode quota.
 */
#include "firmware_bridge.h"
#include "le_nut_ram.h"

static void display_written(void *context, LeNutState *state)
{
    (void)context;
    le_mixed_lcd_update(state);
}

void le_mixed_ram_execute(LeNutState *state, unsigned opcode)
{
    /* Dispatch redirects only supported opcodes. Valid firmware selectors are
     * unchanged; the recovered C's corrupt-selector guard is retained.
     */
    (void)le_nut_ram_execute(LE_NUT_RAM_APRIL, state, opcode,
                             display_written, 0);
}
