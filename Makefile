#
# This is a project Makefile. It is assumed the directory this Makefile resides in is a
# project subdirectory.
#

# config
port = /dev/ttyUSB0 
#port = $(shell echo $(PORT))

# command
MAKE    = make
MRBC    = mrbc
ESPTOOL = esptool.py
MKSPIFFS= mkspiffs
MONITOR = ~/esp/esp-idf/tools/idf_monitor.py
RM      = rm

# files
master = master.rb
slave  = slave.rb
mrbc_exist_master := $(shell find -name master.mrbc)
mrbc_exist_slave  := $(shell find -name slave.mrbc )
mrbc_exist_bin    := $(shell find -name mrbc.spiffs.bin)

# parameters
SPIFFS_DATA_OFFSET=$(shell awk '/spiffs/ {print $$0}' partitions.csv| cut -d , -f 4)
SPIFFS_DATA_TABLE_SIZE=$(shell awk '/spiffs/ {print $$0}' partitions.csv| cut -d , -f 5)

all: single

monitor: 
	$(MONITOR) --port $(port) --baud 115900 ./iotex-esp32-mrubyc.elf

clean:
ifeq ("$(mrbc_exist_bin)","./spiffs/mrbc.spiffs.bin")
	$(RM) ./spiffs/mrbc.spiffs.bin
endif
ifeq ("$(mrbc_exist_master)","./spiffs/mrbc/master.mrbc")
	$(RM) ./spiffs/mrbc/master.mrbc
endif
ifeq ("$(mrbc_exist_slave)","./spiffs/mrbc/slave.mrbc")
	$(RM) ./spiffs/mrbc/slave.mrbc
endif

single:
	$(MRBC) -o ./spiffs/mrbc/master.mrbc -E mrblib/master.rb
	$(MKSPIFFS) -c ./spiffs/mrbc -p 256 -b 4096 -s $(SPIFFS_DATA_TABLE_SIZE) ./spiffs/mrbc.spiffs.bin
	$(ESPTOOL) --chip esp32 --baud 921600 --port $(port) --before default_reset --after hard_reset write_flash -z --flash_mode qio --flash_freq 80m --flash_size detect $(SPIFFS_DATA_OFFSET) ./spiffs/mrbc.spiffs.bin

multi:
	$(MRBC) -o ./spiffs/mrbc/master.mrbc -E mrblib/master.rb
	$(MRBC) -o ./spiffs/mrbc/slave.mrbc  -E mrblib/slave.rb
	$(MKSPIFFS) -c ./spiffs/mrbc -p 256 -b 4096 -s $(SPIFFS_DATA_TABLE_SIZE) ./spiffs/mrbc.spiffs.bin
	$(ESPTOOL) --chip esp32 --baud 921600 --port $(port) --before default_reset --after hard_reset write_flash -z --flash_mode qio --flash_freq 80m --flash_size detect $(SPIFFS_DATA_OFFSET) ./spiffs/mrbc.spiffs.bin


