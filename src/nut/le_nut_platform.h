/* Non-keyboard Nut display/pause/stop orchestration; hardware stays in backend. */
#ifndef LE_NUT_PLATFORM_H
#define LE_NUT_PLATFORM_H
#include "le_recovered.h"
#include "le_display_policy.h"

typedef enum { LE_NUT_PLATFORM_2009, LE_NUT_PLATFORM_APRIL } LeNutPlatformVariant;
typedef struct {
    void *context;
    void (*render)(void *context, LeNutState *state, LeDisplayPolicy *policy);
    uint32_t (*read_word)(void *context, uint32_t address);
    void (*set_clock)(void *context, uint32_t argument);
    /* Zero means the native decrement loop runs 2^32 iterations, not none. */
    void (*wait)(void *context, uint32_t initial_count);
} LeNutPlatformIo;

/* Return 0 to continue, 1 to stop the interpreter (060), -1 unsupported,
 * -2 missing required backend/policy. Errors preserve state and output.
 * 060 needs neither policy nor backend. 2E0 uses the full following halfword
 * and returns a pointer advanced by two more bytes only for fused 320.
 * Flags and quota are handled by the existing display policy, including its
 * explicit corrected/legacy blink choice. Callbacks may mutate state/counter;
 * later effects must use those updated values. No calibrated delay is assumed.
 */
int le_nut_platform_execute(LeNutPlatformVariant variant, LeNutState *state,
    unsigned opcode, uint16_t next_word, uint32_t next_pointer,
    LeDisplayPolicy *policy, LeDisplayBlinkMode blink_mode,
    const LeNutPlatformIo *io, uint32_t *result_pointer);
#endif
