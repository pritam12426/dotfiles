# Minimum CMake version
cmake_minimum_required(VERSION 4.0)

# About the pi-pico board
set(PICO_BOARD pico_w)
# set(PICO_PLATFORM RP2040)

# Manually extend PATH (needed only if toolchain isn't globally available)
# set(ArmGNUToolChain "/Applications/ArmGNUToolchain/14.2.rel1/arm-none-eabi/bin")
# set(ENV{PICO_SDK_PATH} "$ENV{HOME}/Developer/git_repositorys/pico/pico-sdk-2.1.1")
# set(FREERTOS_KERNEL_PATH "$ENV{HOME}/Developer/git_repositorys/pico/FreeRTOS-Kernel-rp2040")
# set(ENV{PATH} "$ENV{PATH}:${ArmGNUToolChain}")

# Import the Pico SDK and FREE rtos CMake functions
include("$ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake")
# include("${FREERTOS_KERNEL_PATH}/portable/ThirdParty/GCC/RP2040/FreeRTOS_Kernel_import.cmake")
include("${FREERTOS_KERNEL_PATH}/${FREERTOS_KERNEL_RP2040_RELATIVE_PATH}/FreeRTOS_Kernel_import.cmake")

# Project declaration
project(
  main
  VERSION 0.1.0
  DESCRIPTION "Raspberry Pi Pico W Project"
  HOMEPAGE_URL "https://github.com/pritam12426/"
  LANGUAGES C CXX ASM
)

# Configure a header file from a template (optional)
configure_file(${CMAKE_CURRENT_LIST_DIR}/src/CmakeConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/CmakeConfig.h)
add_compile_options(-fdiagnostics-color=always)

##### Language Standards #####
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Export compile_commands.json (useful for clangd, IDEs, static analysis)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

##### Custom binary name #####
set(MAIN_BINARY "RTOS-pico")

##### Source Files #####
file(GLOB
  SRC_FILES
  "${CMAKE_CURRENT_LIST_DIR}/src/functions.c"
)

#### Dependencies ####
# find_package(PkgConfig REQUIRED)
# pkg_check_modules(LIBXML REQUIRED libxml++-5.0)

##### Initialize the Pico SDK (after board is set) #####
pico_sdk_init()

##### Create Executable #####
add_executable(${MAIN_BINARY}
  ${SRC_FILES}
  "${CMAKE_CURRENT_LIST_DIR}/src/main.c"
)

##### Link Standard Pico Libraries #####
target_link_libraries(${MAIN_BINARY} PRIVATE
  pico_stdlib
  # Uncomment when using Pico W
  pico_cyw43_arch_none

  # Add FREE RTOS to the project
  # FreeRTOS-Kernel
  # FreeRTOS-Kernel-Core
  FreeRTOS-Kernel-Heap4
  # FreeRTOS-Kernel-Static
)

##### Include Directories #####
target_include_directories(${MAIN_BINARY} PRIVATE
  ${PROJECT_SOURCE_DIR}/
  ${PROJECT_SOURCE_DIR}/src
  ${CMAKE_CURRENT_BINARY_DIR}  # for the generated CmakeConfig.h
)

##### USB / UART output settings #####
pico_enable_stdio_usb(${MAIN_BINARY}  1)   # Enable USB output
pico_enable_stdio_uart(${MAIN_BINARY} 1)  # Enable UART output

##### Adding metadate to the elf binry #####
pico_set_program_name(${MAIN_BINARY}            ${PROJECT_NAME})
pico_set_program_url(${MAIN_BINARY}             ${PROJECT_HOMEPAGE_URL})
pico_set_program_version(${MAIN_BINARY}        "${PROJECT_VERSION}")
pico_set_program_description(${MAIN_BINARY}     ${PROJECT_DESCRIPTION})

##### Generate UF2 and other output formats #####
pico_add_extra_outputs(${MAIN_BINARY})

##### Custom Target (Optional) #####
# Custom target to copy .uf2 to mounted Pico
add_custom_target(flash
  COMMAND printf "Looking for Pico mass storage device...\n"
  COMMAND picotool load -f ${CMAKE_BINARY_DIR}/${MAIN_BINARY}.uf2
  DEPENDS ${MAIN_BINARY}
  COMMENT "Flashing UF2 to Raspberry Pi Pico :: ${MAIN_BINARY}.uf2"
)

add_custom_target(memmap
  COMMAND arm-none-eabi-nm -S --size-sort -t d ${CMAKE_BINARY_DIR}/${MAIN_BINARY}.elf > ${CMAKE_BINARY_DIR}/memmap.txt
  COMMAND less -Rir ${CMAKE_BINARY_DIR}/memmap.txt
  DEPENDS ${MAIN_BINARY}
  COMMENT "Generating memory map report to memmap.txt"
)

add_custom_target(disasm
  COMMAND arm-none-eabi-objdump -d ${CMAKE_BINARY_DIR}/${MAIN_BINARY}.elf > ${CMAKE_BINARY_DIR}/disasm.S
  COMMAND bat ${CMAKE_BINARY_DIR}/disasm.S
  DEPENDS ${MAIN_BINARY}
  COMMENT "Generating disassembly to disasm.S"
)

add_custom_target(smonitor
  COMMAND screen /dev/tty.usbmodem* 115200
  COMMENT "Connecting to serial monitor of pico"
)
