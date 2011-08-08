[+ autogen5 template +]

## Created by Anjuta
MCU = [+MCU+]
TARGET = [+Name+]
F_CPU = [+F_CPU+]UL

## Optimization can be
#  0, 1, 2, 3, s
OPT = [+OPT+]

CSRC = [+Name+].c
[+IF (=(get "UseLib") "1")+]CSRC += lib/utils.c[+ENDIF+]
[+ IF (=(get "configUSART0") "1" ) +]CSRC += lib/usart.c[+ENDIF+]

## Format can be
# ihex, binary, srec
FORMAT = [+OUTPUT_FORMAT+]

CSTANDARD = gnu99

DEBUG = dwarf-2

## Enter programmer hardware
#  For a full list enter
#  avrdude -c?
AVRDUDE_PROGRAMMER = [+AVRDUDE_PROGRAMMER+]

## Enter Baudrate 
#  Only for serial programmers or FastBoot
PROGRAMMER_BAUDRATE = [+PROGRAMMER_BAUDRATE+]

## Enter Communication Port
#  Examples:
#  usb
#  /dev/ttyS0
PROGRAMMER_PORT = [+PROGRAMMER_PORT+]

Ext_lib_path= ./lib/
EXTRAINCDIRS = . $(Ext_lib_path)


CC = avr-gcc
CFLAGS = -mmcu=$(MCU)
CFLAGS += -DF_CPU=$(F_CPU)
CFLAGS += -std=$(CSTANDARD)
CFLAGS += -g$(DEBUG) 
CFLAGS += -O$(OPT)
CFLAGS += -Werror -Wall -Wextra -Wstrict-prototypes
CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CFLAGS += $(patsubst %,-I%,$(EXTRAINCDIRS))
#CFLAGS += -Wa,-adhlns=$(<:.c=.lst)

# Compiler flags to generate dependency files.
### GENDEPFLAGS = -Wp,-M,-MP,-MT,$(*F).o,-MF,.dep/$(@F).d
GENDEPFLAGS = -MD -MP -MF .dep/$(@F).d

ALL_CFLAGS = $(CFLAGS) $(GENDEPFLAGS)


OBJECT = $(CSRC:.c=.o)
INCFLAGS = 
LDFLAGS = -Wl,-Map=$(TARGET).map,--cref
LIBS = 

OBJCOPY        = avr-objcopy
OBJDUMP        = avr-objdump
SIZE           = avr-size
SHELL          = sh
REMOVE         = rm -f
COPY           = cp

all: build

build: elf hex eep

elf: $(TARGET).elf
hex: $(TARGET).hex
eep: $(TARGET).eep

$(TARGET).elf: $(OBJECT)
	$(CC) $(ALL_CFLAGS) $(LDFLAGS) -o $@ $^ $(LIBS)

.SUFFIXES:
.SUFFIXES:	.c .cc .C .cpp .o

# Link: create ELF output file from object files.
.SECONDARY : $(TARGET).elf
.PRECIOUS : $(OBJECT)
%.elf: $(OBJECT)
	$(CC) $(ALL_CFLAGS) $(OBJECT) --output $@ $(LDFLAGS)

# Create final output files (.hex, .eep) from ELF output file.
%.hex: %.elf
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@

%.eep: %.elf
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# Compile: create object files from C source files.
%.o : %.c
	$(CC) -c $(ALL_CFLAGS) $< -o $@

count:
	wc *.c *.cc *.C *.cpp *.h *.hpp

# Target: clean project.
clean: 
	$(REMOVE) $(TARGET).hex
	$(REMOVE) $(TARGET).eep
	$(REMOVE) $(TARGET).obj
	$(REMOVE) $(TARGET).cof
	$(REMOVE) $(TARGET).elf
	$(REMOVE) $(TARGET).map
	$(REMOVE) $(TARGET).obj
	$(REMOVE) $(TARGET).a90
	$(REMOVE) $(TARGET).sym
	$(REMOVE) $(TARGET).lnk
	$(REMOVE) $(TARGET).lss
	$(REMOVE) $(OBJECT)
	$(REMOVE) $(LST)
	$(REMOVE) $(SRC:.c=.s)
	$(REMOVE) $(SRC:.c=.d)
	$(REMOVE) .dep/*
    
install:[+ IF (=(get "PROGRAMMER") "avrdude") +]
	avrdude -p$(MCU) -P$(PROGRAMMER_PORT) -c$(AVRDUDE_PROGRAMMER) -b$(PROGRAMMER_BAUDRATE) -U flash:w:$(TARGET).hex
[+ELSE+]
	bootloader -d $(PROGRAMMER_PORT) -b $(PROGRAMMER_BAUDRATE) -p $(TARGET).hex
[+ENDIF+]

# Include the dependency files.
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)


.PHONY: all
.PHONY: count
.PHONY: clean
