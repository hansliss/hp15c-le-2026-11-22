#include "le_keyboard_profile.h"

LeKeyboardProfile le_keyboard_profile_default(void)
{
    const LeKeyboardProfile profile = {3, 5, 8};
    return profile;
}

int le_keyboard_profile_valid(const LeKeyboardProfile *profile)
{
    unsigned timer = profile->timer_units;
    return profile->press_samples >= 1 && profile->press_samples <= 5
        && profile->release_samples >= 3 && profile->release_samples <= 7
        && (timer == 6 || timer == 7 || timer == 8 || timer == 10 || timer == 12);
}

unsigned le_keyboard_profile_value(const LeKeyboardProfile *profile, unsigned field)
{
    if (field == 1) return profile->press_samples;
    if (field == 2) return profile->release_samples;
    return field == 3 ? profile->timer_units : 0;
}

void le_keyboard_profile_next(LeKeyboardProfile *profile, unsigned field)
{
    if (field == 1)
        profile->press_samples = profile->press_samples == 5 ? 1 : profile->press_samples + 1;
    else if (field == 2)
        profile->release_samples = profile->release_samples == 7 ? 3 : profile->release_samples + 1;
    else if (field == 3) {
        switch (profile->timer_units) {
        case 6: profile->timer_units = 7; break;
        case 7: profile->timer_units = 8; break;
        case 8: profile->timer_units = 10; break;
        case 10: profile->timer_units = 12; break;
        default: profile->timer_units = 6; break;
        }
    }
}

uint32_t le_keyboard_profile_encode(const LeKeyboardProfile *profile)
{
    return LE_KEYBOARD_PROFILE_TAG | profile->press_samples
        | ((uint32_t)profile->release_samples << 4)
        | ((uint32_t)profile->timer_units << 8);
}

int le_keyboard_profile_decode(uint32_t value, uint32_t check, LeKeyboardProfile *profile)
{
    if ((value & UINT32_C(0xfffff000)) != LE_KEYBOARD_PROFILE_TAG || check != ~value)
        return 0;
    LeKeyboardProfile decoded = {
        value & 15u, (value >> 4) & 15u, (value >> 8) & 15u
    };
    if (!le_keyboard_profile_valid(&decoded)) return 0;
    *profile = decoded;
    return 1;
}
