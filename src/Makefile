CC = gcc

DEFS = -DHAVE_CONFIG_H -DINLINE=inline
LIBS = -lm -lz 

TARGET_BASE_NAME = clc88

FINALTARGET = $(TARGET_BASE_NAME)
TARGET = $(FINALTARGET)

CFLAGS = -O2 -Wall

OBJDIR= ../obj

OBJS = $(addprefix $(OBJDIR)/, \
	clc88.o \
	cpu.o \
	cpu/z80/z80.o \
	cpu/m6502/m6502.o \
	)
	
all: $(FINALTARGET)	

$(OBJDIR)/%.o: %.c
	@mkdir -p $(dir $@) 2> /dev/null 
	$(CC) -c -o $@ $(DEFS) -I. $(CFLAGS) $<

$(TARGET): $(OBJS)
	$(CC) -o $@ $(LDFLAGS) $(OBJS) $(LIBS)
	
	
clean:
	rm $(TARGET) $(OBJS)
	