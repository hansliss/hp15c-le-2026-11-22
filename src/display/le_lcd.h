/* Stateful renderer recovered from the three HP-15C LE ARM firmwares. */
#ifndef LE_LCD_H
#define LE_LCD_H

#include "le_display_policy.h"

/* The 2009 release has a different disable decision when mode is nonzero.
 * This variant is independent of the optional opcode quota.
 */
typedef enum {
    LE_LCD_APRIL = 0,
    LE_LCD_2009 = 1
} LeLcdVariant;

/* Logical projection, not a packed ARM memory layout. The caller owns the
 * correspondence to calculator state and the per-release cache/mode globals.
 * All fields, including cache, must be initialized from the desired state.
 */
typedef struct {
    LeDisplayFlags flags;
    uint8_t mode;
    uint8_t battery;
    uint64_t source_b0;
    uint64_t source_b8;
    uint64_t cache[2];
} LeLcdState;

/* Required synchronous backend. Reads/writes use physical register addresses;
 * the backend owns controller side effects and frame timing. Helper callbacks
 * may change the shared state through context, as native callees/IRQs may.
 * read32/write32 must not mutate the calculator-state projection itself.
 * No generic or guessed enable/disable implementation is supplied here.
 */
typedef struct {
    void *context;
    uint32_t (*read32)(void *context, uint32_t address);
    void (*write32)(void *context, uint32_t address, uint32_t value);
    void (*enable)(void *context, unsigned contrast);
    void (*disable)(void *context);
    void (*wait_frames)(void *context, unsigned frames);
} LeLcdIo;

/* Recovered renderer body: cached mapping, battery electrode, controller
 * selection and blink setup. Returns after the same logical operations as
 * the ARM routine. It does not promise the ARM routine's incidental r0 value.
 * Does not implement Nut execution or the five opcode quota gates; use the
 * display-policy callback to connect those to this function.
 */
/* Project calculator state into LCD segments and synchronize controller mode. */
void le_lcd_update(LeLcdVariant variant, LeLcdState *state, const LeLcdIo *io);

#endif
