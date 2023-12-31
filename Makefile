# Directories
MSPGCC_ROOT_DIR =  /home/skinnt1/dev/tools/msp430-gcc-9.3.1.11_linux64
MSPGCC_BIN_DIR = $(MSPGCC_ROOT_DIR)/bin
MSPGCC_INCLUDE_DIR = $(MSPGCC_ROOT_DIR)/include
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj
BIN_DIR = $(BUILD_DIR)/bin
TI_CCS_DIR = /home/skinnt1/dev/tools/ccs1250/ccs
DEBUG_BIN_DIR = $(TI_CCS_DIR)/ccs_base/DebugServer/bin
DEBUG_DRIVERS_DIR = $(TI_CCS_DIR)/ccs_base/DebugServer/drivers

LIB_DIRS = $(MSPGCC_INCLUDE_DIR)
INCLUDE_DIRS = $(MSPGCC_INCLUDE_DIR) \
			   ./src \
			   ./external/ \
			   ./external/printf

# Toolchain
CC = $(MSPGCC_BIN_DIR)/msp430-elf-gcc
RM = rm
DEBUG = LD_LIBRARY_PATH=$(DEBUG_DRIVERS_DIR) $(DEBUG_BIN_DIR)/mspdebug
CPPCHECK = cppcheck

# Files
TARGET = $(BIN_DIR)/nsumo

SOURCES_WITH_HEADERS = \
		src/drivers/uart.c \
		src/drivers/i2c.c \
		src/app/drive.c \
		src/app/enemy.c \

SOURCES = \
		src/main.c \
		$(SOURCES_WITH_HEADERS)

HEADERS = \
		$(SOURCES_WITH_HEADERS:.c=.h) \
		src/common/defines.h \

OBJECT_NAMES = $(SOURCES:.c=.o)
OBJECTS = $(patsubst %,$(OBJ_DIR)/%,$(OBJECT_NAMES))

# Static Analysis
## Don't check the msp430 helper headers (they have a LOT of ifdefs)
CPPCHECK_INCLUDES = ./src
CPPCHECK_IGNORE = external/printf
CPPCHECK_FLAGS = \
	--quiet --enable=all --error-exitcode=1 \
	--inline-suppr \
	--suppress=missingIncludeSystem \
	--suppress=unmatchedSuppression \
	--suppress=unusedFunction \
	$(addprefix -I,$(CPPCHECK_INCLUDES)) \
	$(addprefix -i,$(CPPCHECK_IGNORE))

# Flags
MCU = msp430g2553
WFLAGS = -Wall -Wextra -Werror -Wshadow
CFLAGS = -mmcu=$(MCU) $(WFLAGS) $(addprefix -I,$(INCLUDE_DIRS)) -Og -g
LDFLAGS = -mmcu=$(MCU) $(addprefix -L,$(LIB_DIRS))

# Build
## Linking
$(TARGET): $(OBJECTS) $(HEADERS)
	echo $(OBJECTS)
	@mkdir -p $(dir $@)
	$(CC) $(LDFLAGS) $^ -o $@

## Compiling
$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c -o $@ $^

# Phonies
.PHONY: all clean flash cppcheck

all: $(TARGET)

clean:
	@$(RM) -rf $(BUILD_DIR)

flash: $(TARGET)
	@$(DEBUG) tilib "prog $(TARGET)"

cppcheck:
	@$(CPPCHECK) --quiet --enable=all --error-exitcode=1 \
	--inline-suppr \
	-I $(INCLUDE_DIRS) \
	$(SOURCES) \
	-i external/printf
	@$(CPPCHECK) $(CPPCHECK_FLAGS) $(SOURCES)

format:
	@$(FORMAT) -i $(SOURCES) $(HEADERS)