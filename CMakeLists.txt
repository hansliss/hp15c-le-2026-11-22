cmake_minimum_required(VERSION 3.20)
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)
    message(FATAL_ERROR "Use a separate build directory, for example cmake -S . -B build")
endif()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/arm7tdmi.cmake"
    CACHE FILEPATH "ARM7TDMI compiler toolchain")
project(hp15c_le LANGUAGES C ASM)

find_package(Python3 3.8 REQUIRED COMPONENTS Interpreter)
find_program(ARM_LD arm-none-eabi-ld REQUIRED)
find_program(LLVM_OBJCOPY NAMES llvm-objcopy-17 llvm-objcopy REQUIRED)

set(STOCK_FIRMWARE "" CACHE FILEPATH "Original HP-15C LE firmware BIN")
if(NOT EXISTS "${STOCK_FIRMWARE}")
    message(FATAL_ERROR "Set -DSTOCK_FIRMWARE to a stock HP15C+ BIN listed in README.md")
endif()

set(image_tool "${CMAKE_CURRENT_SOURCE_DIR}/tools/build_image.py")
set(rom "${CMAKE_CURRENT_BINARY_DIR}/nut-rom.bin")
set(stock_selection "${CMAKE_CURRENT_BINARY_DIR}/stock-firmware.path")
file(GENERATE OUTPUT "${stock_selection}" CONTENT "${STOCK_FIRMWARE}\n")
add_custom_command(OUTPUT "${rom}"
    COMMAND "${Python3_EXECUTABLE}" "${image_tool}" rom "${STOCK_FIRMWARE}" "${rom}"
    DEPENDS "${STOCK_FIRMWARE}" "${stock_selection}" "${image_tool}" rom/revisions.json
            rom/2011-04-11.patch rom/2009-08-19.patch rom/expanded.patch
    VERBATIM)
set_source_files_properties(src/platform/firmware.s PROPERTIES OBJECT_DEPENDS "${rom}")

set(keyboard_sources
    src/keyboard/le_keyboard_platform.c
    src/keyboard/le_keyboard_scan.c
    src/keyboard/le_keyboard_profile.c)

# Preserve the hardware-tested link order for reproducible flash addresses.
add_library(firmware_objects OBJECT
    src/platform/firmware.s
    src/display/display_entry.s
    src/display/display_bridge.c
    src/display/le_display.c
    src/display/le_display_policy.c
    src/display/le_lcd.c
    src/display/le_lcd_hw.c
    src/nut/le_nut_ram.c
    src/nut/le_nut_control.c
    src/nut/le_nut_pointer.c
    src/nut/le_nut_transfer.c
    src/nut/le_nut_field.c
    src/nut/le_nut_compare.c
    src/nut/le_nut_arithmetic.c
    src/nut/le_nut_decimal.c
    src/nut/le_nut_flow.c
    src/nut/le_nut_misc.c
    src/nut/le_nut_platform.c
    ${keyboard_sources}
    src/nut/ram_bridge.c
    src/nut/control_bridge.c
    src/nut/pointer_bridge.c
    src/nut/transfer_bridge.c
    src/nut/field_bridge.c
    src/nut/compare_bridge.c
    src/nut/arithmetic_bridge.c
    src/nut/flow_bridge.c
    src/nut/misc_bridge.c
    src/nut/platform_bridge.c
    src/nut/dispatch.c
    src/platform/keyboard_entry.s
    src/platform/board_services.c
    src/platform/board_entries.s)
set_target_properties(firmware_objects PROPERTIES
    C_STANDARD 11 C_STANDARD_REQUIRED YES C_EXTENSIONS NO)
target_include_directories(firmware_objects PRIVATE src/platform src/display src/nut)
target_compile_definitions(firmware_objects PRIVATE
    "$<$<COMPILE_LANGUAGE:C>:LE_MIXED_QUOTA=0;LE_MIXED_BLINK_LEGACY=0>")
target_compile_options(firmware_objects PRIVATE
    -mcpu=arm7tdmi
    "$<$<COMPILE_LANGUAGE:C>:-marm;-Os;-ffreestanding;-fno-builtin;-fno-unwind-tables;-fno-asynchronous-unwind-tables;-ffunction-sections;-fdata-sections;-Wall;-Wextra;-Werror>")
set_source_files_properties(${keyboard_sources} PROPERTIES
    COMPILE_OPTIONS -O2
    COMPILE_DEFINITIONS "LE_KEYBOARD_RUNTIME_PROFILE;KEYBOARD_TUNING")

set(linker_script "${CMAKE_CURRENT_SOURCE_DIR}/src/platform/firmware.ld")
set(image "${CMAKE_CURRENT_BINARY_DIR}/HP15C_LE_2026-11-22.bin")
add_custom_command(OUTPUT "${image}"
    BYPRODUCTS firmware.elf firmware.map firmware.raw
    COMMAND "${ARM_LD}" -T "${linker_script}" --gc-sections -z noexecstack -Map=firmware.map
            -o firmware.elf $<TARGET_OBJECTS:firmware_objects>
    COMMAND "${LLVM_OBJCOPY}" -O binary firmware.elf firmware.raw
    COMMAND "${Python3_EXECUTABLE}" "${image_tool}" seal firmware.raw "${rom}" "${image}"
    DEPENDS firmware_objects $<TARGET_OBJECTS:firmware_objects> "${linker_script}" "${image_tool}" "${rom}"
    COMMAND_EXPAND_LISTS VERBATIM)
add_custom_target(firmware ALL DEPENDS "${image}")
add_custom_target(verify
    COMMAND "${Python3_EXECUTABLE}" "${image_tool}" verify "${image}"
    DEPENDS firmware VERBATIM)
