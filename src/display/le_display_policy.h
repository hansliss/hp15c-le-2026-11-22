/* Display-request policy recovered from the April HP-15C LE handlers. */
#ifndef LE_DISPLAY_POLICY_H
#define LE_DISPLAY_POLICY_H

#include <stdint.h>

typedef enum {
    LE_DISPLAY_QUOTA_DISABLED = 0, /* Working default; also zero initialization. */
    LE_DISPLAY_QUOTA_APRIL = 1
} LeDisplayQuotaMode;

typedef enum {
    LE_DISPLAY_BLINK_ENABLE = 0, /* Correct 030 behavior. */
    LE_DISPLAY_BLINK_LEGACY_TOGGLE = 1 /* Original LE comparison only. */
} LeDisplayBlinkMode;

typedef struct {
    LeDisplayQuotaMode mode;
    uint32_t counter; /* ARM word at 0x00200010; compared as signed. */
} LeDisplayPolicy;

typedef struct {
    uint8_t off;   /* State byte 0x42: zero permits display. */
    uint8_t blink; /* State byte 0x43. */
} LeDisplayFlags;

/* Required synchronous callback. It may update flags and counter, just as
 * code called by the ARM handlers can. It must not change the policy mode.
 * Actual rendering, frame waits and controller I/O belong to the callback.
 */
typedef void (*LeDisplayRender)(void *context, LeDisplayPolicy *policy,
                                LeDisplayFlags *flags);

/* Initialize with the working no-quota policy and counter zero. Set mode
 * explicitly to LE_DISPLAY_QUOTA_APRIL to select original April behavior.
 */
void le_display_policy_init(LeDisplayPolicy *policy);

/* Display-related wrapper actions only; not a replacement Nut interpreter.
 * Begin clears counter and blink, leaving off untouched. End requests a final
 * render unconditionally, outside the five opcode quota gates. Call begin/end
 * once per interpreter-wrapper invocation, never once per Nut instruction.
 */
void le_display_run_begin(LeDisplayPolicy *policy, LeDisplayFlags *flags);
void le_display_run_end(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                         LeDisplayRender render, void *context);

/* Gate an already prepared display request. Opcode flag changes and fused
 * instruction handling remain the caller's responsibility. This boundary is
 * used by the mixed firmware while those native prefixes remain assembly.
 */
void le_display_request(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                         LeDisplayRender render, void *context);

/* Apply the display prefix for opcode 018, 030, 118, 2e0 or 320, including
 * opcode flag changes followed by the optional April quota. Returns 1 when
 * 2e0 consumes a following 320; otherwise 0. Unsupported opcodes return -1
 * without changing state or calling render. next_word is the full next ROM
 * word, used only by 2e0; the caller advances its ROM pointer on return 1.
 *
 * 030 retains LE toggling semantics, including blink != 1 for nonboolean
 * diagnostic values. This does not implement Nonpareil's blink-enable rule.
 * 018/118 delay, clock, key-wait and C.X effects are outside this function.
 * All pointers and render must be valid. See DISPLAY_POLICY.md for scope.
 */
/* Explicit behavior selection for corrected emulation and legacy comparison.
 * ENABLE makes every 030 set off=0/blink=1. No blink-phase timing is invented.
 * The original le_display_event below remains the recovered legacy oracle.
 */
int le_display_event_with_blink(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                     unsigned opcode, uint16_t next_word, LeDisplayBlinkMode blink_mode,
                     LeDisplayRender render, void *context);

int le_display_event(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                     unsigned opcode, uint16_t next_word,
                     LeDisplayRender render, void *context);

#endif
