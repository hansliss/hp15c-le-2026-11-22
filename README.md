# HP-15C LE firmware reimplementation

This project builds a replacement firmware image for the HP-15C Limited
Edition. OpenAI Codex did most of the disassembly analysis, C implementation,
and automated comparisons. Hans Liss directed the work and tested the
firmware and keyboard response on a physical calculator.

The firmware runs the calculator's Nut ROM with a C interpreter and an
expanded 208-register pool (64 in stock firmware). The revised MEM display
handles three-digit register counts. The firmware also corrects several
display and blink problems, and uses a new debounce scanner with a
settings menu in the factory settings.

## INSTALLATION

You will need the **serial pogo-pin cable** to program the HP 15C-LE. This
cable has a special locking pogo-pin connector in one end, a small black
box with a blue "ERASE" and a blue "RESET" button in the middle, and a DE-9
serial connector in the other end. **It is NOT the same cable used
with the modern HP-15C Collector's Edition! That cable is USB and not
in any way compatible with the LE.**

You will also need the ```MySamBa.exe``` program to send the firmware file
to the calculator. If you have the cable, you probably also have the program
already. Otherwise it's included in this repo, under [flashing](flashing).

Remove the battery cover, attach the pogo connector in the correct orientation
(hint: look at the width of the two tabs on the side of the connector).

Connect the other end of the cable to a serial port, e.g. a USB-to-serial
adapter. Do NOT use a TTL or 3.3V serial adapter; you need a real RS-232
DE-9 male plug to match the female plug on the programming cable.

Identify the serial port, for instance using Device Manager to look for
a likely COM port. While you're there, check what kind of port it is.
If it is a CH340 USB-to-serial interface, go to the Drivers tab and check
the version of the driver. Don't bother closing that dialog in that case.
See further down for more info on this.

Start MySamba.exe, select the serial port and browse for the 128k .bin file
that contains the firmware you just built. *Do not press Send yet!*

* Turn on the calculator.
* On the cable's control box, start holding down *ERASE*.
* Press and release *RESET*. The calculator turns off.
* Press its "On" button to turn it back on.
* Let go of *ERASE*.
* Press *RESET* again.
* Finally press the "On" button. (I tend to hold it down for a very short
period of time rather than just a quick press, to make sure it registers,
because typically the display stays blank here)

Now click the Send button in MySamba, and hopefully you will see the progress
bar filling.

Don't panic if this doesn't work. The process is notoriously finicky, and
you will probably think you have bricked the calculator at some point. Keep
retrying the procedure exactly as described, and it should succeed.

### CH340

If you get permission errors when trying to send, and your serial port is
a CH340-based USB-to-serial adapter, try finding an older driver version
for the CH340, and change driver. How to do that is beyond the scope of this
README, but I am using a driver version 3.5.2019.1, dated 2019-01-30.

## BUILD

You need CMake 3.20 or newer, Python 3.8 or newer, Clang with the ARM target,
LLVM objcopy, GNU `arm-none-eabi-ld`, and a build tool such as Make or Ninja.
The reference build used Clang and LLVM 17.0.6 and GNU ld 2.42.

Supply one original HP-15C LE firmware BIN with its exact filename. For
example, keep it in a local `stock/` directory and select it at configure
time. The build verifies the whole input and its extracted Nut ROM by SHA-256.
It brings the older ROM revisions to the April 15 baseline, applies the
expanded-memory patch, and verifies the resulting ROM. The project does not
ship the ROM or the original BINs.

| Stock filename | SHA-256 |
| --- | --- |
| `HP15C+ 08-19-09.bin` | `bbfb2c3f86d954af07c95c184edf87260cd31b261747d5e92f9937952172f7f9` |
| `HP15C+ 04-11-11.bin` | `436a203da8e4bd1d3bf1d791ea0bf19dfff53c9a879aeb24bae211fad21a4d83` |
| `HP15C+ 04-15-11 LATEST.bin` | `6631bc6cb8ad1c064db199c3a14ff80e13c267232996ef143ae7c7f3a9b422a9` |

From the project root, adjust the path in the first command to select your
stock file.

```sh
cmake -S . -B build -DSTOCK_FIRMWARE="$PWD/stock/HP15C+ 04-15-11 LATEST.bin"
cmake --build build --parallel
cmake --build build --target verify
```

The firmware file is `build/HP15C_LE_2026-11-22.bin` (131,072 bytes).
The build writes the LE image checksum. The optional `verify` target checks
the whole result against the standalone reference, whose SHA-256 is
`5222d4c01656773f5a63f158a374867bc9d4e6761ab94429ea5e3d6f740a75f2`.
Clean builds with all three stock inputs produced this same image.
Compiler or linker changes can change the output bytes.

## NOTES

### Stock firmware bugs

The numbers follow Katie Wasserman's *HP-15C LE (Limted Edition) Bug Reports*,
which covers the April 15, 2011 stock firmware. Hardware observations and
emulator results are called out where their coverage differs.

| # | Stock behavior | Status in this firmware |
| --- | --- | --- |
| 1 | Repeated program PSE can blank the display. PSE with SF 9 can flash incorrectly. | Removed the display refresh quota. The reported PSE cases passed on hardware. The two-pause factorial case and full-value overflow blink also passed in the emulator. |
| 2 | Repeated combinations or permutations can flash the result. | Removing the quota fixed the flash in emulator comparisons. The symptom could not be reproduced in the hardware comparison. A related missing “running” indication after Cy,x was fixed on hardware by making blink requests enable blinking consistently. |
| 3 | The manual's self-test can corrupt program memory and show Error 9. | The original diagnostic routines are retained. This report was outside the repair work. |
| 4 | Holding a key was reported to draw more than 20 mA. | No dedicated power fix was made. The new scanner may already eliminate the symptom. A hardware current-measurement setup and held-key tests are pending. |
| 5 | The low-battery warning may fail, and low voltage or weak batteries can cause memory loss. | No low-battery or retention fix. Physical low-voltage testing is pending. |
| 6 | Holding roll-down during the LCD diagnostic can leave the diagnostic and run the current program. | The original LCD diagnostic behavior is retained. |
| 7–9 | A single digit pressed during the imaginary-part, PREFIX, or MEM temporary view can flash when the view ends. | Removed the quota-triggered blink. The digit is still accepted and is steady after the view closes. All three cases passed on hardware. |
| 10 | Keyboard PSE accepts input during the pause, unlike the 15C Classic. | This LE behavior was confirmed and accepted. Input is still delivered after the pause. |

### Keyboard scanner

Stock hardware can register double presses or drop presses, especially during
program entry. The new scanner uses per-key press and release thresholds and
is the only scanner in the image. The default is three press samples, five
release samples, and eight timer units. The factory menu's `4.P` submenu can
change these values and retain them across normal off/on. Hardware regression
testing found the response satisfactory. Rare contact failures and held-key
current have not been quantified.

I need to point out that this has been difficult to verify on real hardware,
since the LE sometimes tends to improve with use. Presumably, the keys aren't
very high quality and may be contaminated with oxide or some other substance
that wears off with use. All I know is that my particular specimen now works
almost flawlessly after being more or less unusable for it's entire life.

### Developer pointers

- Start with `src/nut/dispatch.c` and `src/platform/le_recovered.h` for the
  tagged ROM pointer, opcode dispatch, and calculator state layout.
  `src/nut/dispatch_table.inc` assigns each of the 1,024 encodings to a handler group.
- `src/keyboard/` contains the scanner, profile handling, and board bindings.
  `src/display/` contains LCD rendering and display policy.
- `src/platform/firmware.s` contains the retained April 15 ARM platform.
  Startup, interrupts, timers and diagnostics share fixed addresses with C.
  The zero-filled gaps reserve the original offsets of the remaining code.
  `firmware.ld` sets the flash layout, and `firmware_bridge.h` declares the
  interpreter and display entry points. Both factory version encodings are
  in `firmware.s`. The retained words include live literal pools, lookup
  tables, and computed branch targets. The original zero-init descriptor
  and Nut RAM page table are also retained at their fixed addresses. No
  current reader was identified for those two blocks.
- `src/platform/board_services.c` contains the C implementations of the key
  queue, checksum, field cache and contrast services. `board_entries.s` aligns
  the stack and adapts the original callers at their fixed entry addresses.
  The C key ring preserves the legacy wrap and full-queue rules, and the
  shims preserve the original peek and enqueue return-register conventions.
- The word edits in `rom/` record the expected old word and its replacement.
  The expanded patch builds on the [memory patch by J-F Garnier,
  Hrastprogrammer, and Eric Smith](https://www.hpmuseum.org/forum/thread-18491-post-162115.html#pid162115).

The 0BSD license covers original project contributions. The supplied HP
firmware, the extracted Nut ROM, and the stock-derived ARM code retain their
existing provenance and rights.
