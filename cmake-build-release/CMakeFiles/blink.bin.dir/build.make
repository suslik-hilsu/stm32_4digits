# CMAKE generated file: DO NOT EDIT!
# Generated by "MinGW Makefiles" Generator, CMake Version 3.17

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Disable VCS-based implicit rules.
% : %,v


# Disable VCS-based implicit rules.
% : RCS/%


# Disable VCS-based implicit rules.
% : RCS/%,v


# Disable VCS-based implicit rules.
% : SCCS/s.%


# Disable VCS-based implicit rules.
% : s.%


.SUFFIXES: .hpux_make_needs_suffix_list


# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

SHELL = cmd.exe

# The CMake executable.
CMAKE_COMMAND = "D:\Jetbrains Toolbox\apps\CLion\ch-0\202.8194.17\bin\cmake\win\bin\cmake.exe"

# The command to remove a file.
RM = "D:\Jetbrains Toolbox\apps\CLion\ch-0\202.8194.17\bin\cmake\win\bin\cmake.exe" -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = E:\MK\projects\stm_test\proj

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = E:\MK\projects\stm_test\proj\cmake-build-release

# Utility rule file for blink.bin.

# Include the progress variables for this target.
include CMakeFiles/blink.bin.dir/progress.make

CMakeFiles/blink.bin: blink
	E:\xpack-arm-none-eabi-gcc-9.3.1-1.3\bin\arm-none-eabi-objcopy.exe -Obinary blink blink.bin

blink.bin: CMakeFiles/blink.bin
blink.bin: CMakeFiles/blink.bin.dir/build.make

.PHONY : blink.bin

# Rule to build all files generated by this target.
CMakeFiles/blink.bin.dir/build: blink.bin

.PHONY : CMakeFiles/blink.bin.dir/build

CMakeFiles/blink.bin.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles\blink.bin.dir\cmake_clean.cmake
.PHONY : CMakeFiles/blink.bin.dir/clean

CMakeFiles/blink.bin.dir/depend:
	$(CMAKE_COMMAND) -E cmake_depends "MinGW Makefiles" E:\MK\projects\stm_test\proj E:\MK\projects\stm_test\proj E:\MK\projects\stm_test\proj\cmake-build-release E:\MK\projects\stm_test\proj\cmake-build-release E:\MK\projects\stm_test\proj\cmake-build-release\CMakeFiles\blink.bin.dir\DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/blink.bin.dir/depend

