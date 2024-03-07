RTEMSPREFIX = /home/developer/rtems-6

OBJDIR = build
SRC = $(wildcard *.c)
OBJS = $(SRC:%.c=$(OBJDIR)/%.o)
INIT = $(filter $(OBJDIR)/init.o,$(OBJS))
LIBS = $(filter-out $(OBJDIR)/init.o,$(OBJS))
EXE = $(OBJDIR)/init.exe
TARFILE = tarfile.o

a9: CC=arm-rtems6-gcc
a9: LD=arm-rtems6-ld
a9: AR=arm-rtems6-ar
a9: RL=arm-rtems6-ranlib
a9: SIZE=arm-rtems6-size
a9: OBJCOPY=arm-rtems6-objcopy
a9: SPECFLAGS=-B$(RTEMSPREFIX)/arm-rtems6/xilinx_zynq_a9_qemu/lib -qrtems
a9: BSPFLAGS=-march=armv7-a -mthumb -mfpu=neon -mfloat-abi=hard -mtune=cortex-a9
a9: LINKCMDS = $(RTEMSPREFIX)/arm-rtems6/xilinx_zynq_a9_qemu/lib/linkcmds

zed: CC=arm-rtems6-gcc
zed: LD=arm-rtems6-ld
zed: AR=arm-rtems6-ar
zed: RL=arm-rtems6-ranlib
zed: SIZE=arm-rtems6-size
zed: OBJCOPY=arm-rtems6-objcopy
zed: SPECFLAGS=-B$(RTEMSPREFIX)/arm-rtems6/xilinx_zynq_zedboard/lib -qrtems
zed: BSPFLAGS=-march=armv7-a -mthumb -mfpu=neon -mfloat-abi=hard -mtune=cortex-a9
zed: LINKCMDS = $(RTEMSPREFIX)/arm-rtems6/xilinx_zynq_zedboard/lib/linkcmds

beagle: CC=arm-rtems6-gcc
beagle: LD=arm-rtems6-ld
beagle: AR=arm-rtems6-ar
beagle: RL=arm-rtems6-ranlib
beagle: SIZE=arm-rtems6-size
beagle: OBJCOPY=arm-rtems6-objcopy
beagle: SPECFLAGS=-B$(RTEMSPREFIX)/arm-rtems6/beagleboneblack/lib -qrtems
beagle: BSPFLAGS=-mcpu=cortex-a8
beagle: LINKCMDS = $(RTEMSPREFIX)/arm-rtems6/beagleboneblack/lib/linkcmds

i686: CC=i386-rtems6-gcc
i686: LD=i386-rtems6-ld
i686: AR=i386-rtems6-ar
i686: RL=i386-rtems6-ranlib
i686: SIZE=i386-rtems6-size
i686: OBJCOPY=i386-rtems6-objcopy
i686: SPECFLAGS=-B$(RTEMSPREFIX)/i386-rtems6/pc686/lib -qrtems
i686: BSPFLAGS=-march=i686 -mtune=i686
i686: RELLOCADDR=-Wl,-Ttext,0x00100000
i686: LINKCMDS = $(RTEMSPREFIX)/i386-rtems6/pc686/lib/linkcmds

leon3: CC=sparc-rtems6-gcc
leon3: LD=sparc-rtems6-ld
leon3: AR=sparc-rtems6-ar
leon3: RL=sparc-rtems6-ranlib
leon3: SIZE=sparc-rtems6-size
leon3: OBJCOPY=sparc-rtems6-objcopy
leon3: SPECFLAGS=-B$(RTEMSPREFIX)/sparc-rtems6/leon3/lib -qrtems
leon3: BSPFLAGS=-mcpu=leon3
leon3: LINKCMDS = $(RTEMSPREFIX)/sparc-rtems6/leon3/lib/linkcmds

rpi4: CC=aarch64-rtems6-gcc
rpi4: LD=aarch64-rtems6-ld
rpi4: AR=aarch64-rtems6-ar
rpi4: RL=aarch64-rtems6-ranlib
rpi4: SIZE=aarch64-rtems6-size
rpi4: OBJCOPY=aarch64-rtems6-objcopy
rpi4: SPECFLAGS=-B$(RTEMSPREFIX)/aarch64-rtems6/raspberrypi4b/lib -qrtems
rpi4: BSPFLAGS=-mcpu=cortex-a72 -march=armv8-a
rpi4: LINKCMDS = $(RTEMSPREFIX)/aarch64-rtems6/raspberrypi4b/lib/linkcmds

a9 i686 leon3 rpi4 beagle zed: all

all: dir exe

$(OBJDIR)/%.o: %.c
	$(CC) $(SPECFLAGS) $(BSPFLAGS) -c -o $@ $<

lib:
	$(LD) -r $(LIBS) -o $(OBJDIR)/relocatable.obj

tar-prep:
	mkdir -p build/tarfs/mnt/
	cp -r build/*.o build/tarfs/mnt/
	cp -r build/*.obj build/tarfs/mnt/
	cp -r shell-script build/tarfs/mnt/

tar: tar-prep
	cd build/tarfs; tar cf ../tarfile $(shell ls build/tarfs)
	cd build; $(LD) -r --noinhibit-exec -o $(TARFILE) -b binary tarfile

exe: $(OBJS) lib tar
	$(CC) $(SPECFLAGS) $(BSPFLAGS) $(RELLOCADDR) -o $(INIT)-prelink $(INIT) $(OBJDIR)/$(TARFILE) $(LINKLIBRARIES)
	rtems-syms -v -e -c "$(BSPFLAGS)" -C $(CC) -o $(INIT)-dl-sym.o $(INIT)-prelink
	$(CC) $(SPECFLAGS) $(BSPFLAGS) $(RELLOCADDR) -o $(EXE) $(INIT) $(INIT)-dl-sym.o $(OBJDIR)/$(TARFILE) $(LINKLIBRARIES)
	$(OBJCOPY) -O binary --strip-all $(EXE) $(EXE).bin
	$(SIZE) $(EXE)
	#gzip -9 $(EXE).bin
	#mkimage -A arm -O rtems -T kernel -a 0x80000000 -e 0x80000000 -n RTEMS -d $(EXE).bin.gz build/init.img

run-a9:
	qemu-system-arm -M xilinx-zynq-a9 -m 256M \
		-no-reboot -serial null -serial mon:stdio -nographic \
		-kernel $(EXE) \

run-i686:
		qemu-system-i386 -m 128 -display none -no-reboot -serial mon:stdio \
		-kernel $(EXE) \
		-append '--console=/dev/com1'

run-leon3:
	sparc-rtems6-sis -r $(EXE)

run-rpi4:
	./qemu-system-aarch64 -M raspi4b2g -m 2G \
		-no-reboot -serial mon:stdio -nographic \
		-kernel $(EXE).bin

dir:
	mkdir -p build/

clean:
	-rm -rf build/*

.PHONY: dir tar tar-prep lib exe clean run
