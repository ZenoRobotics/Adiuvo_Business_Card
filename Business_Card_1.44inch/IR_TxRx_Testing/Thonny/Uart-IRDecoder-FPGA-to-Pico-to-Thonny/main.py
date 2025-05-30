# UART RX Checker End of Data Tx Chain
from machine import Pin,UART
import time
import sys

uart = UART(0, baudrate=9600, parity=None, stop=1, bits=8, tx=Pin(0), rx=Pin(1))
#uart.init(bits=8, parity=None, stop=2)
led = Pin(Pin.OUT)
led.toggle()
count = 0
sys.stdout.write("Start of RP2040 UART Test \n");

while True:
    
    if  uart.any() > 0:
        data = uart.read()
        data_int = int.from_bytes(data, "big")
        sys.stdout.write('rcvd data back ' + str(data_int) + '... cnt = ')
        sys.stdout.write(str(count) + '\n')
        count = count + 1
    time.sleep(0.02)


