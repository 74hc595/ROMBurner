// Pin definitions
// PORTC pins 0-5: lower 6 data bits
// PORTD pins 6-7 (digital 6-7): upper 2 data bits
// PORTB pin 0 (digital 8): address serial data
// PORTB pin 1 (digital 9): address serial clock
// PORTD pin 5 (digital 5): address latch clock
// PORTB pin 2 (digital 10): /WE
// PORTB pin 3 (digital 11): /OE
// PORTB pin 4 (digital 12): /CS
#define addressLatchPin  5
#define addressClockPin  9
#define addressDataPin   8
#define wePin            10
#define oePin            11
#define csPin            12

// Remote commands
#define readMemCmd       0xFE
#define writeMemCmd      0xFD
#define romLoadStartCmd  0xF3
#define romLoadEndCmd    0xF2
#define successResponse  0x01

// Set the 16 address lines.
void setAddress(int addr)
{
  int addrlo = addr & 0xFF;
  int addrhi = (addr >> 8) & 0xFF;
  digitalWrite(addressLatchPin, LOW);
  shiftOut(addressDataPin, addressClockPin, MSBFIRST, addrhi);
  shiftOut(addressDataPin, addressClockPin, MSBFIRST, addrlo);
  digitalWrite(addressLatchPin, HIGH);
}

// Set up the data lines for input. (read)
void dataInput()
{
  DDRC &= ~B00111111;
  DDRD &= ~B11000000;
}

// Set up the data lines for output. (write)
void dataOutput()
{
  DDRC |= B00111111;
  DDRD |= B11000000;
}

// Indicate error by slowly blinking LED.
void error()
{
  for (;;)
  {
    digitalWrite(13, HIGH);
    delay(500);
    digitalWrite(13, LOW);
    delay(500);
  }
}

void blinkFast()
{
  for (;;)
  {
    digitalWrite(13, HIGH);
    delay(100);
    digitalWrite(13, LOW);
    delay(100);
  }
}

byte readByte(int addr)
{
  setAddress(addr);
  dataInput();
  digitalWrite(csPin, LOW); // select chip
  digitalWrite(oePin, LOW); // output byte
  byte b = PINC | (PIND & B11000000); // read byte
  digitalWrite(oePin, HIGH);
  digitalWrite(csPin, HIGH); // deselect chip
  return b;
}

// Handle a memory read command.
void readMem()
{
  while (Serial.available() < 3) {}
  int addr = Serial.read() << 8; // high byte
  addr |= Serial.read(); // low byte
  int count = Serial.read(); // byte count
  for (int i = 0; i < count; i++)
  {
    byte b = readByte(addr);
    Serial.write(b); // send byte back to host
    addr++;
  }
}

// Handle a memory write command.
void writeMem()
{
  static int ledState = LOW;
  
  while (Serial.available() < 3) {}
  int addr = Serial.read() << 8; // high byte
  addr |= Serial.read(); // low byte
  int count = Serial.read(); // byte count
  byte b;
  
  while (Serial.available() < count) {} // wait for bytes
  for (int i = 0; i < count; i++)
  {
    setAddress(addr);
    dataOutput();
   
    b = Serial.read();
    PORTC = b & B00111111; // set data lines
    PORTD &= ~B11000000;
    PORTD |= b & B11000000;
    digitalWrite(wePin, LOW); // write enable
    digitalWrite(csPin, LOW); // select chip (starts write)
    digitalWrite(csPin, HIGH); // deselect chip
    digitalWrite(wePin, HIGH);
    dataInput();
    addr++;
  }
  
  // wait until last write finishes
  while (readByte(addr-1) != b) {}

  // twiddle the LED
  digitalWrite(13, ledState);
  ledState = (ledState == HIGH) ? LOW : HIGH;
  
  // send success response
  Serial.write(successResponse);
}

void setup()
{
  // Initialize control lines; disable ROM chip
  pinMode(csPin, OUTPUT);
  digitalWrite(csPin, HIGH);
  pinMode(wePin, OUTPUT);
  digitalWrite(wePin, HIGH);
  pinMode(oePin, OUTPUT);
  digitalWrite(oePin, HIGH);
  
  // Initialize address lines
  pinMode(addressLatchPin, OUTPUT);
  pinMode(addressClockPin, OUTPUT);
  pinMode(addressDataPin, OUTPUT);
  
  // Initialize data lines
  dataInput();
  
  // Initialize serial port
  Serial.begin(38400);

  // Turn on LED
  digitalWrite(13, HIGH);
}

void loop()
{
  if (Serial.available() > 0)
  {
    byte inByte = Serial.read();
    switch (inByte)
    {
      case readMemCmd: // read sequence of bytes
        readMem();
        break;
      case writeMemCmd: // write sequence of bytes
        writeMem();
        break;
      case romLoadStartCmd: // ROM load start (send success)
        Serial.write(successResponse);
        break;
      case romLoadEndCmd: // ROM load end (nothing to do)
        digitalWrite(13, HIGH);
        break;
      default:
        error();
    }
  }
}
