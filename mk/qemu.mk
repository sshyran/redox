QEMU=SDL_VIDEO_X11_DGAMOUSE=0 qemu-system-$(ARCH)
QEMUFLAGS=-d cpu_reset -d guest_errors
QEMUFLAGS+=-smp 4 -m 2048
QEMU_EFI=/usr/share/OVMF/OVMF_CODE.fd
ifeq ($(serial),no)
	QEMUFLAGS+=-chardev stdio,id=debug -device isa-debugcon,iobase=0x402,chardev=debug
else
	QEMUFLAGS+=-chardev stdio,id=debug,signal=off,mux=on,"$(if $(qemu_serial_logfile),logfile=$(qemu_serial_logfile))"
	QEMUFLAGS+=-serial chardev:debug -mon chardev=debug
endif
ifeq ($(iommu),yes)
	QEMUFLAGS+=-machine q35,iommu=on
else
	QEMUFLAGS+=-machine q35
endif
ifneq ($(audio),no)
	QEMUFLAGS+=-device ich9-intel-hda -device hda-duplex
endif
ifeq ($(net),no)
	QEMUFLAGS+=-net none
else
	ifneq ($(bridge),)
		QEMUFLAGS+=-netdev bridge,br=$(bridge),id=net0 -device e1000,netdev=net0,id=nic0
	else
	    ifeq ($(net),redir)
			# port 8080 and 8083 - webservers
			# port 64126 - our gdbserver implementation
			QEMUFLAGS+=-netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::8083-:8083,hostfwd=tcp::64126-:64126 -device e1000,netdev=net0,id=nic0
		else
			QEMUFLAGS+=-netdev user,id=net0 -device e1000,netdev=net0 \
						-object filter-dump,id=f1,netdev=net0,file=build/network.pcap
		endif
	endif
endif
ifeq ($(vga),no)
	QEMUFLAGS+=-nographic -vga none
endif
ifneq ($(usb),no)
	QEMUFLAGS+=-device nec-usb-xhci,id=xhci -device usb-tablet,bus=xhci.0
endif
ifeq ($(gdb),yes)
	QEMUFLAGS+=-s
endif
ifeq ($(UNAME),Linux)
	ifneq ($(kvm),no)
		QEMUFLAGS+=-enable-kvm -cpu host
	else
		QEMUFLAGS+=-cpu max
	endif
endif
#,int,pcall
#-device intel-iommu

ifeq ($(UNAME),Linux)
build/extra.bin:
	fallocate --posix --length 1G $@
else
build/extra.bin:
	truncate -s 1g $@
endif

qemu: build/harddrive.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/harddrive.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/harddrive.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_efi: build/harddrive-efi.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-drive file=build/harddrive-efi.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_efi_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-drive file=build/harddrive-efi.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_nvme: build/harddrive.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/harddrive.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_nvme_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/harddrive.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_nvme_efi: build/harddrive-efi.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-drive file=build/harddrive-efi.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_nvme_efi_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-drive file=build/harddrive-efi.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_nvme_live: build/livedisk.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/livedisk.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_nvme_live_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/livedisk.bin,format=raw,if=none,id=drv0 -device nvme,drive=drv0,serial=NVME_SERIAL \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_live: build/livedisk.bin build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/livedisk.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_live_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/livedisk.bin,format=raw \
		-drive file=build/extra.bin,format=raw

qemu_iso: build/livedisk.iso build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-boot d -cdrom build/livedisk.iso \
		-drive file=build/extra.bin,format=raw

qemu_iso_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-boot d -cdrom build/livedisk.iso \
		-drive file=build/extra.bin,format=raw

qemu_iso_efi: build/livedisk-efi.iso build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-boot d -cdrom build/livedisk-efi.iso \
		-drive file=build/extra.bin,format=raw

qemu_iso_efi_no_build: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-bios $(QEMU_EFI) \
		-boot d -cdrom build/livedisk-efi.iso \
		-drive file=build/extra.bin,format=raw

qemu_extra: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/extra.bin,format=raw

qemu_nvme_extra: build/extra.bin
	$(QEMU) $(QEMUFLAGS) \
		-drive file=build/extra.bin,format=raw,if=none,id=drv1 -device nvme,drive=drv1,serial=NVME_EXTRA

qemu_aarch64_virt: build/u-boot.bin build/kernel.uimage
	$(QEMU) $(QEMU_AARCH64_VIRT_FLAGS) \
		-bios $<

# Needed so build/u-boot.bin doesn't pass along ARCH to the sub-make. If ARCH is set that breaks the u-boot build.
MAKEOVERRIDES :=

QEMU_AARCH64_VIRT_FLAGS := -M virt -cpu cortex-a57 -m 2048 -nographic -device loader,file=build/kernel.uimage,addr=0x41000000,force-raw=on

build/u-boot.bin: bootloader-uboot
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -C $< clean
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -C $< qemu_arm64_defconfig
	sed -i 's/^CONFIG_BOOTCOMMAND.*$$/CONFIG_BOOTCOMMAND="bootm 41000000 - $${fdtcontroladdr}"/g' $</.config
	sed -i 's/^CONFIG_BOOTDELAY.*$$/CONFIG_BOOTDELAY=0/g' $</.config
	$(MAKE) CROSS_COMPILE=aarch64-linux-gnu- -C $< -j `$(NPROC)`
	mkdir -p build
	cp $</u-boot.bin $@

build/kernel.uimage: build/kernel
	mkimage -A arm64 -O linux -T kernel -C none -a 0x40000000 -e 0x40001000 -n 'Redox kernel (qemu AArch64 virt)' -d $< $@
