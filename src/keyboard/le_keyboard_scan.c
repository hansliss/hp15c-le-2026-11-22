#include "le_keyboard_scan.h"

void le_keyboard_scan_reset(LeKeyboardScan *state)
{
    state->raw[0]=state->raw[1]=0;
    state->stable[0]=state->stable[1]=0;
    for (unsigned key=0;key<40;key++) state->run[key]=0;
    state->sweeps=state->reserved=0;
#ifdef LE_KEYBOARD_RUNTIME_PROFILE
    state->reserved=LE_KEY_PRESS_SAMPLES | (LE_KEY_RELEASE_SAMPLES<<8)
        | (LE_KEY_SCAN_TIMER_UNITS<<16);
#endif
}

#ifdef LE_KEYBOARD_RUNTIME_PROFILE
int le_keyboard_scan_configure(LeKeyboardScan *state, const LeKeyboardProfile *profile)
{
    if (!le_keyboard_profile_valid(profile)) return 0;
    le_keyboard_scan_reset(state);
    state->reserved=profile->press_samples | ((uint32_t)profile->release_samples<<8)
        | ((uint32_t)profile->timer_units<<16);
    return 1;
}
#endif

static unsigned row_bits(uint32_t low,uint32_t high,unsigned row)
{
    if (row<3) return (low>>(row*10))&1023u;
    /* Physical ON is independent of the row3/column0 matrix position. */
    return ((low>>30)|(high<<2))&1022u;
}

void le_keyboard_scan_step(LeKeyboardScan *state,uint32_t low,uint32_t high,
                           LeKeyboardResult *result)
{
    high &= LE_KEY_VALID_HIGH;
    result->fresh[0]=low&~state->raw[0];
    result->fresh[1]=high&~state->raw[1];
    result->pressed[0]=result->pressed[1]=0;
    result->ambiguous[0]=result->ambiguous[1]=0;
    /* Two rows sharing two closed columns form an ambiguous rectangle. Do not
     * invent an ordering or accept a new corner; existing keys can release. */
    for (unsigned a=0;a<4;a++) {
        for (unsigned b=a+1;b<4;b++) {
            unsigned shared=row_bits(low,high,a)&row_bits(low,high,b);
            if (!shared || !(shared&(shared-1u))) continue;
            for (unsigned column=0;column<10;column++) {
                if (!(shared&(1u<<column))) continue;
                unsigned ka=a*10+column,kb=b*10+column;
                result->ambiguous[ka>>5]|=1u<<(ka&31);
                result->ambiguous[kb>>5]|=1u<<(kb&31);
            }
        }
    }
    state->raw[0]=low;
    state->raw[1]=high;
    state->sweeps++;
    for (unsigned key=0;key<40;key++) {
        unsigned bank=key>>5;
        uint32_t bit=1u<<(key&31);
        unsigned down=(state->raw[bank]&bit)!=0;
        unsigned held=(state->stable[bank]&bit)!=0;
        if (down==held || (!held && (result->ambiguous[bank]&bit))) {
            state->run[key]=0;
            continue;
        }
#ifdef LE_KEYBOARD_RUNTIME_PROFILE
        unsigned threshold=down ? (key==30 ? 1u : state->reserved&255u)
                                : (state->reserved>>8)&255u;
#else
        unsigned threshold=down ? (key==30 ? 1u : LE_KEY_PRESS_SAMPLES)
                                : LE_KEY_RELEASE_SAMPLES;
#endif
        if (++state->run[key]<threshold) continue;
        state->run[key]=0;
        if (down) {
            state->stable[bank]|=bit;
            result->pressed[bank]|=bit;
        } else state->stable[bank]&=~bit;
    }
    /* Keep the foreground awake during initial qualification and brief release
     * dropouts; otherwise ordinary backup can reboot the filter mid-contact. */
    result->activity[0]=state->raw[0]|state->stable[0];
    result->activity[1]=state->raw[1]|state->stable[1];
}
