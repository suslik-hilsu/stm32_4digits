GET_FILENAME_COMPONENT(STM32_CMAKE_DIR ${CMAKE_CURRENT_LIST_FILE} DIRECTORY)
SET(CMAKE_MODULE_PATH ${STM32_CMAKE_DIR} ${CMAKE_MODULE_PATH})

SET(STM32_SUPPORTED_FAMILIES L0 L1 L4 F0 F1 F2 F3 F4 F7 G0 H7 CACHE INTERNAL "stm32 supported families")

IF(STM32_CHIP)
	 SET(STM32_CHIP "${STM32_CHIP}" CACHE STRING "STM32 chip to build for")
ENDIF()

IF(NOT TOOLCHAIN_PREFIX)
     SET(TOOLCHAIN_PREFIX "/usr")
     MESSAGE(STATUS "No TOOLCHAIN_PREFIX specified, using default: " ${TOOLCHAIN_PREFIX})
ELSE()
     FILE(TO_CMAKE_PATH "${TOOLCHAIN_PREFIX}" TOOLCHAIN_PREFIX)
ENDIF()

IF(NOT TARGET_TRIPLET)
    SET(TARGET_TRIPLET "arm-none-eabi")
    MESSAGE(STATUS "No TARGET_TRIPLET specified, using default: " ${TARGET_TRIPLET})
ENDIF()

IF(NOT STM32_FAMILY)
    MESSAGE(STATUS "No STM32_FAMILY specified, trying to get it from STM32_CHIP")
    IF(NOT STM32_CHIP)
        SET(STM32_FAMILY "F1" CACHE INTERNAL "stm32 family")
        MESSAGE(STATUS "Neither STM32_FAMILY nor STM32_CHIP specified, using default STM32_FAMILY: ${STM32_FAMILY}")
    ELSE()
        STRING(REGEX REPLACE "^[sS][tT][mM]32(([fF][0-47])|([gG][0])|([hH]7)|([lL][0-14])|([tT])|([wW])).+$" "\\1" STM32_FAMILY ${STM32_CHIP})
        STRING(TOUPPER ${STM32_FAMILY} STM32_FAMILY)
        MESSAGE(STATUS "Selected STM32 family: ${STM32_FAMILY}")
    ENDIF()
ENDIF()

STRING(TOUPPER "${STM32_FAMILY}" STM32_FAMILY)
LIST(FIND STM32_SUPPORTED_FAMILIES "${STM32_FAMILY}" FAMILY_INDEX)
IF(FAMILY_INDEX EQUAL -1)
    MESSAGE(FATAL_ERROR "Invalid/unsupported STM32 family: ${STM32_FAMILY}")
ENDIF()

SET(TOOLCHAIN_BIN_DIR "${TOOLCHAIN_PREFIX}/bin")
SET(TOOLCHAIN_INC_DIR "${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/include")
SET(TOOLCHAIN_LIB_DIR "${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}/lib")

SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_PROCESSOR arm)

IF (WIN32)
    SET(TOOL_EXECUTABLE_SUFFIX ".exe")
ELSE()
    SET(TOOL_EXECUTABLE_SUFFIX "")
ENDIF()

IF(${CMAKE_VERSION} VERSION_LESS 3.6.0)
    INCLUDE(CMakeForceCompiler)
    CMAKE_FORCE_C_COMPILER("${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOL_EXECUTABLE_SUFFIX}" GNU)
    CMAKE_FORCE_CXX_COMPILER("${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-g++${TOOL_EXECUTABLE_SUFFIX}" GNU)
ELSE()
    SET(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
    SET(CMAKE_C_COMPILER "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOL_EXECUTABLE_SUFFIX}")
    SET(CMAKE_CXX_COMPILER "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-g++${TOOL_EXECUTABLE_SUFFIX}")
ENDIF()
SET(CMAKE_ASM_COMPILER "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gcc${TOOL_EXECUTABLE_SUFFIX}")

SET(CMAKE_OBJCOPY "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objcopy${TOOL_EXECUTABLE_SUFFIX}" CACHE INTERNAL "objcopy tool")
SET(CMAKE_OBJDUMP "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-objdump${TOOL_EXECUTABLE_SUFFIX}" CACHE INTERNAL "objdump tool")
SET(CMAKE_SIZE "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-size${TOOL_EXECUTABLE_SUFFIX}" CACHE INTERNAL "size tool")
SET(CMAKE_DEBUGER "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-gdb${TOOL_EXECUTABLE_SUFFIX}" CACHE INTERNAL "debuger")
SET(CMAKE_CPPFILT "${TOOLCHAIN_BIN_DIR}/${TARGET_TRIPLET}-c++filt${TOOL_EXECUTABLE_SUFFIX}" CACHE INTERNAL "C++filt")

SET(CMAKE_C_FLAGS_DEBUG "-Og -g" CACHE INTERNAL "c compiler flags debug")
SET(CMAKE_CXX_FLAGS_DEBUG "-Og -g" CACHE INTERNAL "cxx compiler flags debug")
SET(CMAKE_ASM_FLAGS_DEBUG "-g" CACHE INTERNAL "asm compiler flags debug")
SET(CMAKE_EXE_LINKER_FLAGS_DEBUG "-Xlinker -Map=output.map" CACHE INTERNAL "linker flags debug")

SET(CMAKE_C_FLAGS_RELEASE "-Os -flto" CACHE INTERNAL "c compiler flags release")
SET(CMAKE_CXX_FLAGS_RELEASE "-Os -flto" CACHE INTERNAL "cxx compiler flags release")
SET(CMAKE_ASM_FLAGS_RELEASE "" CACHE INTERNAL "asm compiler flags release")
SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "-Xlinker -Map=output.map -s -flto" CACHE INTERNAL "linker flags release")

SET(CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_PREFIX}/${TARGET_TRIPLET}" ${EXTRA_FIND_PATH})
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

FUNCTION(STM32_ADD_HEX_BIN_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
      SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
      SET(FILENAME "${TARGET}")
    ENDIF()
    ADD_CUSTOM_TARGET(${TARGET}.hex ALL DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Oihex ${FILENAME} ${FILENAME}.hex)
    ADD_CUSTOM_TARGET(${TARGET}.bin ALL DEPENDS ${TARGET} COMMAND ${CMAKE_OBJCOPY} -Obinary ${FILENAME} ${FILENAME}.bin)
ENDFUNCTION()

FUNCTION(STM32_ADD_DUMP_TARGET TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
      SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
      SET(FILENAME "${TARGET}")
    ENDIF()
    ADD_CUSTOM_TARGET(${TARGET}.dump DEPENDS ${TARGET} COMMAND ${CMAKE_OBJDUMP} -x -D -S -s ${FILENAME} | ${CMAKE_CPPFILT} > ${FILENAME}.dump)
ENDFUNCTION()

FUNCTION(STM32_PRINT_SIZE_OF_TARGETS TARGET)
    IF(EXECUTABLE_OUTPUT_PATH)
      SET(FILENAME "${EXECUTABLE_OUTPUT_PATH}/${TARGET}")
    ELSE()
      SET(FILENAME "${TARGET}")
    ENDIF()
    add_custom_command(TARGET ${TARGET} POST_BUILD COMMAND ${CMAKE_SIZE} ${FILENAME})
ENDFUNCTION()

STRING(TOLOWER ${STM32_FAMILY} STM32_FAMILY_LOWER)
INCLUDE(gcc_stm32f4)

FUNCTION(STM32_SET_FLASH_PARAMS TARGET STM32_FLASH_SIZE STM32_RAM_SIZE STM32_CCRAM_SIZE STM32_MIN_STACK_SIZE STM32_MIN_HEAP_SIZE STM32_FLASH_ORIGIN STM32_RAM_ORIGIN STM32_CCRAM_ORIGIN)
    IF(NOT STM32_LINKER_SCRIPT)
        MESSAGE(STATUS "No linker script specified, generating default")
        INCLUDE(stm32_linker)
        FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld ${STM32_LINKER_SCRIPT_TEXT})
    ELSE()
        CONFIGURE_FILE(${STM32_LINKER_SCRIPT} ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld)
    ENDIF()

    GET_TARGET_PROPERTY(TARGET_LD_FLAGS ${TARGET} LINK_FLAGS)
    IF(TARGET_LD_FLAGS)
        SET(TARGET_LD_FLAGS "\"-T${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld\" ${TARGET_LD_FLAGS}")
    ELSE()
        SET(TARGET_LD_FLAGS "\"-T${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld\"")
    ENDIF()
    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LINK_FLAGS ${TARGET_LD_FLAGS})
ENDFUNCTION()

FUNCTION(STM32_SET_FLASH_PARAMS TARGET FLASH_SIZE RAM_SIZE)
    IF(NOT STM32_FLASH_ORIGIN)
        SET(STM32_FLASH_ORIGIN "0x08000000")
    ENDIF()

    IF(NOT STM32_RAM_ORIGIN)
        SET(STM32_RAM_ORIGIN "0x20000000")
    ENDIF()

    IF(NOT STM32_MIN_STACK_SIZE)
        SET(STM32_MIN_STACK_SIZE "0x200")
    ENDIF()

    IF(NOT STM32_MIN_HEAP_SIZE)
        SET(STM32_MIN_HEAP_SIZE "0")
    ENDIF()

    IF(NOT STM32_CCRAM_ORIGIN)
        SET(STM32_CCRAM_ORIGIN "0x10000000")
    ENDIF()

    IF(NOT STM32_LINKER_SCRIPT)
        MESSAGE(STATUS "No linker script specified, generating default")
        INCLUDE(stm32_linker)
        FILE(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld ${STM32_LINKER_SCRIPT_TEXT})
    ELSE()
        CONFIGURE_FILE(${STM32_LINKER_SCRIPT} ${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld)
    ENDIF()

    GET_TARGET_PROPERTY(TARGET_LD_FLAGS ${TARGET} LINK_FLAGS)
    IF(TARGET_LD_FLAGS)
        SET(TARGET_LD_FLAGS "\"-T${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld\" ${TARGET_LD_FLAGS}")
    ELSE()
        SET(TARGET_LD_FLAGS "\"-T${CMAKE_CURRENT_BINARY_DIR}/${TARGET}_flash.ld\"")
    ENDIF()
    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES LINK_FLAGS ${TARGET_LD_FLAGS})
ENDFUNCTION()

FUNCTION(STM32_SET_TARGET_PROPERTIES TARGET)
    IF(NOT STM32_CHIP_TYPE)
        IF(NOT STM32_CHIP)
            MESSAGE(WARNING "Neither STM32_CHIP_TYPE nor STM32_CHIP selected, you'll have to use STM32_SET_CHIP_DEFINITIONS directly")
        ELSE()
            STM32_GET_CHIP_TYPE(${STM32_CHIP} STM32_CHIP_TYPE)
        ENDIF()
    ENDIF()
    STM32_SET_CHIP_DEFINITIONS(${TARGET} ${STM32_CHIP_TYPE})
    IF(((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE)) AND (NOT STM32_CHIP))
        MESSAGE(FATAL_ERROR "Cannot get chip parameters. Please specify either STM32_CHIP or STM32_FLASH_SIZE/STM32_RAM_SIZE")
    ENDIF()
    IF((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE))
        STM32_GET_CHIP_PARAMETERS(${STM32_CHIP} STM32_FLASH_SIZE STM32_RAM_SIZE STM32_CCRAM_SIZE)
        IF((NOT STM32_FLASH_SIZE) OR (NOT STM32_RAM_SIZE))
            MESSAGE(FATAL_ERROR "Unknown chip: ${STM32_CHIP}. Try to use STM32_FLASH_SIZE/STM32_RAM_SIZE directly.")
        ENDIF()
    ENDIF()
    STM32_SET_FLASH_PARAMS(${TARGET} ${STM32_FLASH_SIZE} ${STM32_RAM_SIZE})
    MESSAGE(STATUS "${STM32_CHIP} has ${STM32_FLASH_SIZE}iB of flash memory and ${STM32_RAM_SIZE}iB of RAM")
ENDFUNCTION()

FUNCTION(STM32_SET_HSE_VALUE TARGET STM32_HSE_VALUE)
    GET_TARGET_PROPERTY(TARGET_DEFS ${TARGET} COMPILE_DEFINITIONS)
    IF(TARGET_DEFS)
        SET(TARGET_DEFS "HSE_VALUE=${STM32_HSE_VALUE};${TARGET_DEFS}")
    ELSE()
        SET(TARGET_DEFS "HSE_VALUE=${STM32_HSE_VALUE}")
    ENDIF()
    SET_TARGET_PROPERTIES(${TARGET} PROPERTIES COMPILE_DEFINITIONS "${TARGET_DEFS}")
ENDFUNCTION()

MACRO(STM32_GENERATE_LIBRARIES NAME SOURCES LIBRARIES)
    STRING(TOLOWER ${STM32_FAMILY} STM32_FAMILY_LOWER)
    FOREACH(CHIP_TYPE ${STM32_CHIP_TYPES})
        STRING(TOLOWER ${CHIP_TYPE} CHIP_TYPE_LOWER)
        LIST(APPEND ${LIBRARIES} ${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER})
        ADD_LIBRARY(${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER} ${SOURCES})
        STM32_SET_CHIP_DEFINITIONS(${NAME}_${STM32_FAMILY_LOWER}_${CHIP_TYPE_LOWER} ${CHIP_TYPE})
    ENDFOREACH()
ENDMACRO()
