# Copyright 2014 The MathWorks, Inc.
# File Name: ArduinoServer.mk
# Template: samtemplate.mk
# Template Version: 1.0 
# Board Type: Arduino Due
# Arduino IDE Version: 1.5.6-r2beta

PLATFORM = [platform]

TARGET = ArduinoServer

ARDUINO_DIR = [arduino_dir]
ARDUINO_SAM_DIR = $(ARDUINO_DIR)/hardware/arduino/sam
ARDUINO_CORE_DIR = $(ARDUINO_DIR)/hardware/arduino/sam/cores/arduino
ARDUINO_CORE_USB_DIR = $(ARDUINO_DIR)/hardware/arduino/sam/cores/arduino/USB
ARDUINO_VARIANT_DIR = $(ARDUINO_SAM_DIR)/variants/arduino_due_x
ARDUINO_LIB_DIR = $(ARDUINO_DIR)/libraries
MAIN_DIR = [server_dir]

#Define all source files
CSRC_FILES = $(ARDUINO_CORE_DIR)/WInterrupts.c $(ARDUINO_CORE_DIR)/cortex_handlers.c $(ARDUINO_CORE_DIR)/syscalls_sam3.c $(ARDUINO_CORE_DIR)/wiring.c \
        $(ARDUINO_CORE_DIR)/wiring_digital.c $(ARDUINO_CORE_DIR)/itoa.c $(ARDUINO_CORE_DIR)/wiring_shift.c $(ARDUINO_CORE_DIR)/wiring_analog.c \
        $(ARDUINO_CORE_DIR)/hooks.c $(ARDUINO_CORE_DIR)/iar_calls_sam3.c $(ARDUINO_CORE_DIR)/avr/dtostrf.c [csrc]
CXXSRC_FILES = $(ARDUINO_CORE_DIR)/WString.cpp $(ARDUINO_CORE_DIR)/RingBuffer.cpp $(ARDUINO_CORE_DIR)/UARTClass.cpp $(ARDUINO_CORE_DIR)/cxxabi-compat.cpp \
         $(ARDUINO_CORE_DIR)/USARTClass.cpp $(ARDUINO_CORE_USB_DIR)/CDC.cpp $(ARDUINO_CORE_USB_DIR)/HID.cpp $(ARDUINO_CORE_USB_DIR)/USBCore.cpp \
         $(ARDUINO_CORE_DIR)/Reset.cpp $(ARDUINO_CORE_DIR)/Stream.cpp $(ARDUINO_CORE_DIR)/Print.cpp $(ARDUINO_CORE_DIR)/WMath.cpp $(ARDUINO_CORE_DIR)/IPAddress.cpp \
         $(ARDUINO_CORE_DIR)/wiring_pulse.cpp $(ARDUINO_VARIANT_DIR)/variant.cpp [cxxsrc]

# Define all object files.
COBJ_FILES = $(addprefix $(MAIN_DIR)/ArduinoServer/, $(notdir $(CSRC_FILES:.c=.c.o)))
CXXOBJ_FILES = $(addprefix $(MAIN_DIR)/ArduinoServer/, $(notdir $(CXXSRC_FILES:.cpp=.cpp.o)))

ELF_EXT = .elf
HEX_EXT = .hex
TARGET_EXT = .bin
CORE_TARGET = $(MAIN_DIR)/ArduinoServer/core.a
LINKER_TARGET = $(MAIN_DIR)/ArduinoServer/$(TARGET)$(ELF_EXT)
EXE_TARGET = $(MAIN_DIR)/ArduinoServer/MW/$(TARGET)$(TARGET_EXT)

# Place -I options here
CINCLUDE_DIRS = [cinclude_dirs] \
        -I"$(ARDUINO_SAM_DIR)/system/libsam" -I"$(ARDUINO_SAM_DIR)/system/CMSIS/CMSIS/Include" -I"$(ARDUINO_SAM_DIR)/system/CMSIS/Device/ATMEL" -I"$(ARDUINO_CORE_DIR)" -I"$(ARDUINO_CORE_USB_DIR)" -I"$(ARDUINO_VARIANT_DIR)"
CXXINCLUDE_DIRS = [cxxinclude_dirs] \
        -I"$(ARDUINO_SAM_DIR)/system/libsam" -I"$(ARDUINO_SAM_DIR)/system/CMSIS/CMSIS/Include" -I"$(ARDUINO_SAM_DIR)/system/CMSIS/Device/ATMEL" -I"$(ARDUINO_CORE_DIR)" -I"$(ARDUINO_CORE_USB_DIR)" -I"$(ARDUINO_VARIANT_DIR)" 

MCU = [cpu]
F_CPU = [f_cpu]

CFLAGS = -c -g -Os -w -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -Dprintf=iprintf -mcpu=$(MCU) -DF_CPU=$(F_CPU) -DARDUINO=156 -D__SAM3X8E__ -mthumb -DUSBCON -DARDUINO_ARCH_SAM 
CXXFLAGS = $(CFLAGS) -fno-rtti -fno-exceptions -DUSB_PID=0x003e -DUSB_VID=0x2341 [additional_flags]


LINKER_FILE = $(ARDUINO_VARIANT_DIR)/linker_scripts/gcc/flash.ld
LIBSAM_FILE = $(ARDUINO_VARIANT_DIR)/libsam_sam3x8e_gcc_rel.a
LINKER_FLAGS = -Os -Wl,--gc-sections -mcpu=$(MCU) -T $(LINKER_FILE) -o $(LINKER_TARGET) -L/build -lm -lgcc -mthumb -Wl,--cref -Wl,--check-sections -Wl,--gc-sections \
    -Wl,--entry=Reset_Handler -Wl,--unresolved-symbols=report-all -Wl,--warn-common -Wl,--warn-section-align -Wl,--warn-unresolved-symbols \
    -Wl,--start-group $(MAIN_DIR)/ArduinoServer/syscalls_sam3.c.o $(LIBSAM_FILE) $(MAIN_DIR)/ArduinoServer/core.a -Wl,--end-group


PORT = [port]
BAUD_RATE = 1200
UPLOAD_FLAGS = --port=$(notdir $(PORT)) -U false -e -w -v -b -R



# Program settings
ARDUINO_TOOL_DIR = $(ARDUINO_DIR)/hardware/tools/g++_arm_none_eabi/bin
CC = $(ARDUINO_TOOL_DIR)/arm-none-eabi-gcc
CXX = $(ARDUINO_TOOL_DIR)/arm-none-eabi-g++
LINKER = $(ARDUINO_TOOL_DIR)/arm-none-eabi-g++
ARCHIVE = $(ARDUINO_TOOL_DIR)/arm-none-eabi-ar
OBJCOPY = $(ARDUINO_TOOL_DIR)/arm-none-eabi-objcopy
PROGRAMMER = $(ARDUINO_DIR)/hardware/tools/bossac
REMOVE = rm -f
MV = mv -f


# Default target.
all: upload

# Program the device.  
ifeq ($(PLATFORM), Windows)
upload: $(EXE_TARGET)
	mode $(PORT):$(BAUD_RATE) 
	$(PROGRAMMER) $(UPLOAD_FLAGS) $(EXE_TARGET) 2>&1
endif

ifeq ($(PLATFORM), Linux)
upload: $(EXE_TARGET)
	stty -F $(PORT) $(BAUD_RATE) 
	$(PROGRAMMER) $(UPLOAD_FLAGS) $(EXE_TARGET) 2>&1
endif

ifeq ($(PLATFORM), Macintosh)
upload: $(EXE_TARGET)
	stty -f $(PORT) $(BAUD_RATE) 
	$(PROGRAMMER) $(UPLOAD_FLAGS) $(EXE_TARGET) 2>&1
endif



$(EXE_TARGET): $(LINKER_TARGET) 
	$(OBJCOPY) -O binary $(LINKER_TARGET) $(EXE_TARGET)

$(LINKER_TARGET): $(CORE_TARGET)
	$(LINKER) $(LINKER_FLAGS)

# Archive all object files into core.a
$(CORE_TARGET): $(COBJ_FILES) $(CXXOBJ_FILES)
	$(ARCHIVE) rcs $(CORE_TARGET) $(COBJ_FILES) $(CXXOBJ_FILES)



# define pattern rules
$(MAIN_DIR)/ArduinoServer/%.c.o: $(ARDUINO_CORE_DIR)/%.c
	$(CC) $(CINCLUDE_DIRS) $(CFLAGS) $< -o $@ 

$(MAIN_DIR)/ArduinoServer/%.c.o: $(ARDUINO_CORE_DIR)/avr/%.c
	$(CC) $(CINCLUDE_DIRS) $(CFLAGS) $< -o $@ 

[additional_rules_c]

[additional_rules_cxx]

$(MAIN_DIR)/ArduinoServer/%.cpp.o: $(ARDUINO_CORE_DIR)/%.cpp
	$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@ 

$(MAIN_DIR)/ArduinoServer/%.cpp.o: $(ARDUINO_CORE_USB_DIR)/%.cpp
	$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@ 

$(MAIN_DIR)/ArduinoServer/%.cpp.o: $(ARDUINO_VARIANT_DIR)/%.cpp
	$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@ 

# Target: clean project.
clean:
	$(REMOVE) $(CORE_TARGET) $(LINKER_TARGET) $(COBJ_FILES) $(CXXOBJ_FILES) $(EXE_TARGET)

.PHONY:	all build clean upload
