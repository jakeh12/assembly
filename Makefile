TARGET=counter
PROM=AT28C256
SIZE=32768


all:
	zasm -b -i $(TARGET).asm -o $(TARGET).bin
clean:
	rm -f *.bin
flash:
	mkfile -n $(SIZE) $(TARGET)_flash.bin
	dd if=$(TARGET).bin of=$(TARGET)_flash.bin bs=1 conv=notrunc
	minipro -p $(PROM) -w $(TARGET)_flash.bin
	wc -c $(TARGET).bin
	hexdump $(TARGET)_flash.bin
	rm -f *_flash.bin
verify:
	test
