#ifndef LE_KEYBOARD_PROFILE_H
#define LE_KEYBOARD_PROFILE_H
#include <stdint.h>

typedef struct {
    uint8_t press_samples;
    uint8_t release_samples;
    uint8_t timer_units;
} LeKeyboardProfile;

/* Five deliberately bounded choices per field. Timer units are 1/1024 s
 * rearm delays, plus execution/interrupt overhead, not measured sweep times. */
#define LE_KEYBOARD_PROFILE_TAG UINT32_C(0x4b410000)
LeKeyboardProfile le_keyboard_profile_default(void);
int le_keyboard_profile_valid(const LeKeyboardProfile *profile);
/* Menu fields 1, 2, and 3 select press, release, and timer respectively. */
unsigned le_keyboard_profile_value(const LeKeyboardProfile *profile, unsigned field);
/* Advance the menu field, wrapping to its first allowed value. */
void le_keyboard_profile_next(LeKeyboardProfile *profile, unsigned field);
/* Encode a tagged profile for storage alongside its bitwise complement. */
uint32_t le_keyboard_profile_encode(const LeKeyboardProfile *profile);
/* Check the tag, complement, and allowed values before replacing the profile. */
int le_keyboard_profile_decode(uint32_t value, uint32_t check, LeKeyboardProfile *profile);
#endif
