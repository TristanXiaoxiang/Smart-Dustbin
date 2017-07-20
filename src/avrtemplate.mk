# Copyright 2014 The MathWorks, Inc.
# File Name: ArduinoServer.mk
# Template: avrtemplate.mk
# Template Version: 1.0 
# Board Type: Arduinos with Atmega processor
# Arduino IDE Version: 1.5.6-r2beta

PLATFORM = [platform]

TARGET = ArduinoServer
VARIANT = [variant]

ARDUINO_DIR = [arduino_dir]
ARDUINO_AVR_DIR = $(ARDUINO_DIR)/hardware/arduino/avr
ARDUINO_CORE_DIR = $(ARDUINO_DIR)/hardware/arduino/avr/cores/arduino
ARDUINO_VARIANT_DIR = $(ARDUINO_AVR_DIR)/variants/$(VARIANT)
ARDUINO_LIB_DIR = $(ARDUINO_DIR)/libraries
MAIN_DIR = [server_dir]

#Define all source files
CSRC_FILES = $(ARDUINO_CORE_DIR)/hooks.c $(ARDUINO_CORE_DIR)/WInterrupts.c $(ARDUINO_CORE_DIR)/wiring.c $(ARDUINO_CORE_DIR)/wiring_analog.c \
       $(ARDUINO_CORE_DIR)/wiring_digital.c $(ARDUINO_CORE_DIR)/wiring_pulse.c $(ARDUINO_CORE_DIR)/wiring_shift.c [csrc]

CXXSRC_FILES = $(ARDUINO_CORE_DIR)/HardwareSerial.cpp \
       $(ARDUINO_CORE_DIR)/HardwareSerial0.cpp $(ARDUINO_CORE_DIR)/HardwareSerial1.cpp $(ARDUINO_CORE_DIR)/HardwareSerial2.cpp $(ARDUINO_CORE_DIR)/HardwareSerial3.cpp \
       $(ARDUINO_CORE_DIR)/new.cpp $(ARDUINO_CORE_DIR)/Print.cpp $(ARDUINO_CORE_DIR)/Stream.cpp $(ARDUINO_CORE_DIR)/Tone.cpp $(ARDUINO_CORE_DIR)/USBCore.cpp \
       $(ARDUINO_CORE_DIR)/WMath.cpp $(ARDUINO_CORE_DIR)/WString.cpp [cxxsrc]

# Define all object files.
COBJ_FILES = $(addprefix $(MAIN_DIR)/ArduinoServer/, $(notdir $(CSRC_FILES:.c=.c.o)))
CXXOBJ_FILES = $(addprefix $(MAIN_DIR)/ArduinoServer/, $(notdir $(CXXSRC_FILES:.cpp=.cpp.o)))
OBJ_FILES = $(COBJ_FILES) $(CXXOBJ_FILES)

ELF_EXT = .elf
TARGET_EXT = .hex
LINKER_TARGET = $(MAIN_DIR)/ArduinoServer/$(TARGET)$(ELF_EXT)
EXE_TARGET = $(MAIN_DIR)/ArduinoServer/MW/$(TARGET)$(TARGET_EXT)

# Place -I options here
CINCLUDE_DIRS = [cinclude_dirs] -I"$(ARDUINO_CORE_DIR)" -I"$(ARDUINO_VARIANT_DIR)"  
CXXINCLUDE_DIRS = [cxxinclude_dirs] -I"$(ARDUINO_CORE_DIR)" -I"$(ARDUINO_VARIANT_DIR)"

MCU = [cpu]
F_CPU = [f_cpu]

CFLAGS = -mmcu=$(MCU) -MMD -fno-exceptions -ffunction-sections -fdata-sections -g -Os -w -D"F_CPU=$(F_CPU)" [vidpid] -DARDUINO=156 -DARDUINO_ARCH_AVR -c -x none
CXXFLAGS = $(CFLAGS) [additional_flags]


LINKER_FLAGS = -mmcu=$(MCU) -g -Wl,--gc-sections,--relax -Os -lm 


PORT = [port]
UPLOAD_RATE = [upload_rate]
PROTOCOL = [protocol]
UPLOAD_FLAGS = -v -v -v -v -p $(MCU) -c $(PROTOCOL) -P $(PORT) -b $(UPLOAD_RATE) -D -U flash:w:$(EXE_TARGET):i  


# Program settings
ARDUINO_TOOL_DIR = $(ARDUINO_DIR)/hardware/tools/avr/bin
CC = $(ARDUINO_TOOL_DIR)/avr-gcc
CXX = $(ARDUINO_TOOL_DIR)/avr-g++
LINKER = $(ARDUINO_TOOL_DIR)/avr-gcc
ARCHIVE = $(ARDUINO_TOOL_DIR)/avr-ar
SIZE = $(ARDUINO_TOOL_DIR)/avr-size
OBJCOPY = $(ARDUINO_TOOL_DIR)/avr-objcopy

ifeq ($(PLATFORM), Linux)
    PROGRAMMER = $(ARDUINO_DIR)/hardware/tools/avrdude
    CONF_FILE = $(ARDUINO_DIR)/hardware/tools/avrdude.conf
else
    PROGRAMMER = $(ARDUINO_TOOL_DIR)/avrdude
    CONF_FILE = $(ARDUINO_DIR)/hardware/tools/avr/etc/avrdude.conf
endif



REMOVE = rm -f
MV = mv -f


# Default target.
all: upload

# Program the device.  
upload: $(EXE_TARGET)
	$(PROGRAMMER) -C $(CONF_FILE) $(UPLOAD_FLAGS)


$(EXE_TARGET): $(LINKER_TARGET) 
	$(OBJCOPY) -O ihex -R .eeprom $(LINKER_TARGET) $(EXE_TARGET) 

$(LINKER_TARGET): $(COBJ_FILES) $(CXXOBJ_FILES)
	$(LINKER) $(COBJ_FILES) $(CXXOBJ_FILES) $(LINKER_FLAGS) -o $(LINKER_TARGET)


# define pattern rules
$(MAIN_DIR)/ArduinoServer/%.c.o: $(ARDUINO_CORE_DIR)/%.c
	$(CC) $(CINCLUDE_DIRS) $(CFLAGS) $< -o $@ 

[additional_rules_c]

[additional_rules_cxx]

$(MAIN_DIR)/ArduinoServer/%.cpp.o: $(ARDUINO_CORE_DIR)/%.cpp
	$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@ 

$(MAIN_DIR)/ArduinoServer/%.cpp.o: $(MAIN_DIR)/%.cpp
	$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@ 




size:
	$(SIZE) $(EXE_TARGET)

# Target: clean project.
clean:
	$(REMOVE) $(LINKER_TARGET) $(COBJ_FILES) $(CXXOBJ_FILES) $(EXE_TARGET)

.PHONY:	all clean upload size 
