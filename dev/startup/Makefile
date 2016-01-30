OBJECTS68K=startup.o buf.o

LDFLAGS=-M -bamigahunk -r -x -hunkattr startup=0x2005 -hunkattr .tocd=0x2005 -hunkattr .text=0x2005 -hunkattr .rodata=0x2005 -hunkattr .data=0x2005 -hunkattr .bss=0x2005

all: sonnet.o x.o

sonnet.o : $(OBJECTS68K) 
	$(LD) $(LDFLAGS) $(OBJECTS68K) -o $@ 

%.o : %.s 
	$(ASM68K) $(ASM68KPARAM) -o $@ $<

%.o : %.p 
	$(ASMPPC) $(ASMPPCPARAM) -o $@ $< 

clean :
	$(RM) $(OBJECTS68K) sonnet.o x.o


