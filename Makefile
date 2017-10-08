TARGET=counter
PROM=AT28C256

all:
	zasm -buy -i $(TARGET).asm -o $(TARGET).bin
clean:
	rm -f *.bin *.lst
flash:
	minipro -p $(PROM) -w $(TARGET).bin
	wc -c $(TARGET).bin
	hexdump $(TARGET).bin

