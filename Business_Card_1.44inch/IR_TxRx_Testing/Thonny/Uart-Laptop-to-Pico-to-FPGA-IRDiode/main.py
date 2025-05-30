#UART TX Initiator - Start of TX Chain
from machine import Pin,UART
import time
import sys

uart = UART(0, baudrate=9600, parity=None, stop=1, bits=8, tx=Pin(0), rx=Pin(1))

count = 0
sys.stdout.write("Start of RP2040 UART Test \n");

while True:
    uart.write(chr(count))  #74 Hex = b0111 0100
    sys.stdout.write('Count = ' + str(count) + '\n')
    count = count + 1
    
    if count == 127:
        count = 0
    time.sleep(0.1)


