ROMBurner
=========

ROMBurner is an Arduino sketch for burning 8K AT28C64 EEPROM chips.

It uses the same ser09 protocol as Ultim809. Interact with it using [the ser09
script](https://github.com/74hc595/Ultim809/blob/master/code/ser09.py)

Hardware
--------
The sketch is designed for a standard ATmega168/328 Arduino and two 74HC595
shift registers. Communication takes place over the serial port: either through
the USB cable on an Arduino Duemilanove or over an FTDI USB-to-serial cable
(Ardweeny, etc.)

Circuit
-------
I'll have to post a schematic later, but it's a simple circuit.

*  First shift register Q0-Q7 outputs to A0-A7
*  Second shift register Q0-Q4 outputs to A8-A12
*  First shift register Q7' to second shift register DS
*  Digital pin 5 to both shift register RCK pins (12)
*  Digital pin 9 to both shift register SCK pins (11)
*  Digital pin 8 to first shift register DS pin (14)
*  Digital pin 10 to EEPROM /WE pin
*  Digital pin 11 to EEPROM /OE pin
*  Digital pin 12 to EEPROM /CS pin
*  Analog pins 0-5 to EEPROM pins D0-D5
*  Digital pins 6-7 to EEPROM D6 and D7
*  Shift register /OE pins connected to GND
*  Shift register /MR pins connected to Vcc

