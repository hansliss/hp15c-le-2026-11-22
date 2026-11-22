/* AT91SAM7L keyboard and factory-menu bindings for the pinned April-2011
 * corrected parents. Historical scanner labs are not linked into this code. */
#include "le_keyboard_platform.h"
#include "le_recovered.h"
#define REG(address) (*(volatile uint32_t *)(address))
#define RT ((volatile LeKeyboardRuntime *)LE_KEYBOARD_RUNTIME_ADDRESS)
#define CALC ((volatile LeNutState *)0x300000u)
#define RETAIN ((volatile uint32_t *)0x3007f8u)
#define SYSTEM 0x200878u
#define PIO 0xfffff800u
#define ROWS 0x3c000000u
#define ON (1u<<10)
#define WD() (REG(0xfffffd50u)=0xa5000001u)
#define EMPTY() (((int (*)(void))0x110bacu)())
#define CLEAR() (((void (*)(void))0x110bd0u)())
#define ENQUEUE(key) (((void (*)(unsigned))0x110c48u)(key))

static uint32_t irq_off(void)
{
    uint32_t old,masked;
    __asm__ volatile("mrs %0,cpsr\norr %1,%0,#128\nmsr cpsr_c,%1"
                     : "=&r"(old),"=&r"(masked)::"memory","cc");
    return old;
}
static void irq_restore(uint32_t old)
{
    __asm__ volatile("msr cpsr_c,%0"::"r"(old):"memory","cc");
}
/* These trace points have no buffers or logging implementation in the image. */
__attribute__((noinline,used)) void keyboard_observe(unsigned stage,unsigned value)
{
    __asm__ volatile(""::"r"(stage),"r"(value):"memory");
}
#ifdef KEYBOARD_TUNING
static LeKeyboardProfile current_profile(void)
{
    uint32_t packed=RT->scan.reserved;
    LeKeyboardProfile profile={packed&255u,(packed>>8)&255u,(packed>>16)&255u};
    return profile;
}
#endif
unsigned keyboard_timer_units(void) {return (RT->scan.reserved>>16)&255u;}
void keyboard_boot(void)
{
    LeKeyboardProfile profile=le_keyboard_profile_default();
#ifdef KEYBOARD_TUNING
    if (CALC->reset_marker==UINT64_C(0x12bc67d9fe3954af)
        && ((REG(0xfffffd04u)>>8)&7u)!=0u)
        (void)le_keyboard_profile_decode(RETAIN[0],RETAIN[1],&profile);
#endif
    RT->context=0;
    (void)le_keyboard_scan_configure((LeKeyboardScan *)&RT->scan,&profile);
    keyboard_observe(1,1);
}
unsigned keyboard_candidate_scan(void)
{
    uint32_t irq=irq_off(),low=0,high=0;
    for (int row=3;row>=0;row--) {
        REG(PIO+0x14)=ROWS;
        REG(PIO+0x10)=1u<<(row+26);
        ((void (*)(unsigned))0x111944u)(100);
        uint32_t pins=REG(PIO+0x3c);
        unsigned bits=((pins&127u)<<2)|((pins&0x800u)>>2)|((pins&0x3000u)>>12);
        high=(high<<10)|(low>>22);low=(low<<10)|bits;
    }
    REG(PIO+0x10)=ROWS;
    low=~low;high=(~high)&LE_KEY_VALID_HIGH;
    low&=~(1u<<30);
    if (!(REG(PIO+0x3c)&ON)) low|=1u<<30;
    LeKeyboardResult result;
    le_keyboard_scan_step((LeKeyboardScan *)&RT->scan,low,high,&result);
    REG(SYSTEM)=result.activity[0];REG(SYSTEM+4)=result.activity[1];
    if (result.pressed[0]&(1u<<30)) ENQUEUE(30);
    for (unsigned key=0;key<40;key++) {
        if (key!=30 && (result.pressed[key>>5]&(1u<<(key&31)))) ENQUEUE(key);
    }
    unsigned idle=(result.activity[0]|result.activity[1])==0;
    irq_restore(irq);
    return idle;
}
/* Let timer IRQs update the bitmap while waiting for all keys to clear. */
__attribute__((noinline)) void keyboard_wait_release(void)
{
    while (REG(SYSTEM)|REG(SYSTEM+4)) {
        WD();
        __asm__ volatile(".global keyboard_release_poll\nkeyboard_release_poll:":::"memory");
    }
}
#ifdef KEYBOARD_TUNING
/* Format a numeric settings page for the native LCD text routine. */
static void profile_page(unsigned tag,unsigned value)
{
    char text[20];
    for (unsigned i=0;i<20;i++) text[i]=' ';
    text[0]='0'+tag/10u;text[2]='0'+tag%10u;text[3]='.';
    for (unsigned i=10;i>2;i--) {text[(i-1)*2]='0'+value%10u;value/=10u;}
    ((void (*)(const char *))0x10e438u)(text);
    LeKeyboardProfile active=current_profile();
    keyboard_observe(10+tag,le_keyboard_profile_encode(&active));
}
__attribute__((noinline)) static unsigned profile_key(void)
{
    keyboard_wait_release();
    CLEAR();
    keyboard_observe(6,1);
    while (EMPTY()) WD();
    return ((unsigned (*)(void))0x110c10u)();
}
/* Reconfigure timer 0 and persist the profile only after key release. */
__attribute__((noinline)) void keyboard_apply_profile(const LeKeyboardProfile *profile)
{
    if (!le_keyboard_profile_valid(profile)) return;
    keyboard_wait_release();
    uint32_t irq=irq_off();
    ((void (*)(unsigned))0x110e5cu)(0);
    ((void (*)(unsigned))0x110e5cu)(1);
    (void)le_keyboard_scan_configure((LeKeyboardScan *)&RT->scan,profile);
    uint32_t value=le_keyboard_profile_encode(profile);
    RETAIN[0]=value;RETAIN[1]=~value;
    *(volatile uint8_t *)(SYSTEM+8)=255u;
    CLEAR();
    ((void (*)(void))0x110934u)();
    irq_restore(irq);
    keyboard_observe(5,value);
}
__attribute__((noinline)) void keyboard_profile_menu(void)
{
    LeKeyboardProfile working=current_profile();
    unsigned selected=0;
    profile_page(70,0);
    for (;;) {
        unsigned key=profile_key();
        if (key==30) return; /* ON: discard unsaved edits. */
        if (key==25) {keyboard_apply_profile(&working);return;} /* ENTER: save. */
        if (key==16) { /* 4: restore defaults in the working copy. */
            working=le_keyboard_profile_default();selected=0;profile_page(74,0);continue;
        }
        unsigned field=key==26 ? 1u : key==27 ? 2u : key==28 ? 3u : 0u;
        if (!field) continue;
        if (selected==field) le_keyboard_profile_next(&working,field);
        selected=field;
        profile_page(70+field,le_keyboard_profile_value(&working,field));
    }
}
#endif

void keyboard_factory_menu(void *calc)
{
    unsigned was_off=CALC->display_off;
    RT->context=1;
    ((void (*)(unsigned))0x111510u)(0);
    CALC->display_off=0;
    for (;;) {
        keyboard_wait_release();CLEAR();
        ((void (*)(const char *))0x10e438u)((const char *)0x111c44u);
        keyboard_observe(4,1);
        while (!(REG(SYSTEM)|REG(SYSTEM+4))) WD();
        uint32_t low=REG(SYSTEM),high=REG(SYSTEM+4);
        if (high) continue;
        if (low==(1u<<26)) {((void (*)(void *))0x10e6a8u)(calc);continue;}
        if (low==(1u<<27)) {((void (*)(void *,unsigned))0x10e460u)(calc,1234);continue;}
        if (low==(1u<<28)) {((void (*)(void *))0x10d3a8u)(calc);continue;}
#ifdef KEYBOARD_TUNING
        if (low==(1u<<16)) {keyboard_profile_menu();continue;}
#endif
        if (low==(1u<<30)) {keyboard_wait_release();break;}
    }
    keyboard_observe(3,1);
    RT->context=0;
    *(volatile uint8_t *)0x2008a8u=0;
    CLEAR(); /* Do not deliver the menu's physical ON to Nut as well. */
    if (was_off) {
        CALC->display_off=1;ENQUEUE(30);
        ((void (*)(unsigned))0x10fb7cu)(36000000u);
        ((void (*)(void *))0x10d1d8u)(calc);
        ((void (*)(unsigned))0x10fb7cu)(REG(0x2008a0u));
    }
    REG(0x200000u)=REG(0x200004u)=~0u;
    ((void (*)(void *))0x1101e4u)(calc);
    CLEAR();
}
