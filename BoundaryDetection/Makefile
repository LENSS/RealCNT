COMPONENT=ModuleTesterC
#COMPONENT=LogReaderC
#power from 1 to 31
#CFLAGS += -DCC2420_DEF_RFPOWER=31
CFLAGS += -I ../../Neighborhood/src
CFLAGS += -I ../../GeometrySupport/src
CFLAGS += -I ../../Identity/src
CFLAGS += -I$(TOSDIR)/lib/net \
          -I$(TOSDIR)/lib/net/drip
CFLAGS += -DTOSH_DATA_LENGTH=100
include $(MAKERULES)
