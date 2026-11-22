#ifndef LE_KEYBOARD_SCAN_H
#define LE_KEYBOARD_SCAN_H
#include <stdint.h>
#ifdef LE_KEYBOARD_RUNTIME_PROFILE
#include "le_keyboard_profile.h"
#endif

/* Fixed profile: a nominal 8/1024-second sweep interval, three closed samples
 * to press and five open samples to release. ON retains immediate wake behavior.
 * No heap, elapsed-time guesses, last-key mute or automatic repeat. */
#define LE_KEY_PRESS_SAMPLES 3u
#define LE_KEY_RELEASE_SAMPLES 5u
#define LE_KEY_SCAN_TIMER_UNITS 8u
#define LE_KEY_VALID_HIGH UINT32_C(0xf7) /* unused physical position35 */

typedef struct {
    uint32_t raw[2];
    uint32_t stable[2];
    uint8_t run[40];
    uint32_t sweeps;
    /* Zero in the legacy build; release builds pack press/release/timer
     * into successive bytes here, preserving the audited 64-byte layout. */
    uint32_t reserved;
} LeKeyboardScan;
_Static_assert(sizeof(LeKeyboardScan)==64,"Scanner state allocation");

typedef struct {
    uint32_t fresh[2], pressed[2], ambiguous[2], activity[2];
} LeKeyboardResult;
void le_keyboard_scan_reset(LeKeyboardScan *state);
#ifdef LE_KEYBOARD_RUNTIME_PROFILE
/* Apply only with scanning stopped and all keys released. Resets the filter. */
int le_keyboard_scan_configure(LeKeyboardScan *state, const LeKeyboardProfile *profile);
#endif
/* Process one raw sweep and report stable activity and new presses. */
void le_keyboard_scan_step(LeKeyboardScan *state, uint32_t low, uint32_t high,
                           LeKeyboardResult *result);
#endif
