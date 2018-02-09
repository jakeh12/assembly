TARGET=ram_prog
PROM=AT28C256
PORT=/dev/ttyUSB0

all:
	zasm --z80 -buy -i $(TARGET).asm -o $(TARGET).bin
clean:
	rm -f $(TARGET).bin $(TARGET).lst screenlog.*
flash:
	minipro -p $(PROM) -w $(TARGET).bin
	wc -c $(TARGET).bin
	hexdump $(TARGET).bin
monitor:
	screen -L -h 10000 $(PORT) 115200

