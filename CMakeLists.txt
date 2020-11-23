project(blink)
cmake_minimum_required(VERSION 3.0)

enable_language(ASM)

file(GLOB_RECURSE SOURCES
        libs/cmsis/*.s libs/cmsis/*.c
        libs/hal/src/*.c
        src/*.c src/*.cpp)

add_executable(blink ${SOURCES})
target_include_directories(blink PRIVATE
        libs/cmsis/include
        libs/hal/include
        src include)

stm32_set_target_properties(blink)
stm32_print_size_of_targets(blink)
stm32_add_hex_bin_targets(blink)

add_definitions(-DUSE_FULL_LL_DRIVER)

set(STM32_MIN_STACK_SIZE 0x100)