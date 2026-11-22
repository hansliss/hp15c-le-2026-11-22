#include "le_display_policy.h"

void le_display_policy_init(LeDisplayPolicy *policy)
{
    policy->mode = LE_DISPLAY_QUOTA_DISABLED;
    policy->counter = 0;
}

void le_display_run_begin(LeDisplayPolicy *policy, LeDisplayFlags *flags)
{
    policy->counter = 0;
    flags->blink = 0;
}

void le_display_run_end(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                         LeDisplayRender render, void *context)
{
    render(context, policy, flags);
}

void le_display_request(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                           LeDisplayRender render, void *context)
{
    if (policy->mode == LE_DISPLAY_QUOTA_DISABLED) {
        render(context, policy, flags);
        return;
    }

    const uint32_t counter = policy->counter;

    /* ARM's signed comparison treats words with bit 31 set as below six.
     * Keep storage/addition unsigned to preserve wrapping without C overflow
     * or implementation-defined conversion from uint32_t to int32_t.
     */
    if (counter > 6 && counter < UINT32_C(0x80000000)) {
        return;
    }
    if (counter == 6) {
        flags->off = 0;
        flags->blink = 1;
        render(context, policy, flags);
        /* The original reload happens after the call, not from counter. */
        policy->counter += UINT32_C(1);
    } else {
        policy->counter = counter + UINT32_C(1);
        render(context, policy, flags);
    }
}

int le_display_event_with_blink(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                     unsigned opcode, uint16_t next_word, LeDisplayBlinkMode blink_mode,
                     LeDisplayRender render, void *context)
{
    int consumed_toggle = 0;

    switch (opcode) {
    case 0x018:
    case 0x118:
        flags->blink = 0;
        break;
    case 0x030:
        flags->off = 0;
        flags->blink = blink_mode == LE_DISPLAY_BLINK_ENABLE ? 1 : flags->blink != 1;
        break;
    case 0x2e0:
        consumed_toggle = next_word == 0x320;
        flags->off = !consumed_toggle;
        flags->blink = 0;
        break;
    case 0x320:
        flags->off ^= 1;
        break;
    default:
        return -1;
    }

    le_display_request(policy, flags, render, context);
    return consumed_toggle;
}

/* Preserve the recovered stock interface for byte/behavior comparison tools. */
int le_display_event(LeDisplayPolicy *policy, LeDisplayFlags *flags,
                     unsigned opcode, uint16_t next_word,
                     LeDisplayRender render, void *context)
{
    return le_display_event_with_blink(policy, flags, opcode, next_word,
                                      LE_DISPLAY_BLINK_LEGACY_TOGGLE, render, context);
}
