/*
  MWArduino.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
 
  See file LICENSE.txt for licensing terms.
*/

#ifndef MWArduino_h
#define MWArduino_h

#include "Firmata.h" /* Using the Firmata protocol for RS232 serial interface */
#include "LibraryBase.h"

#define MAX_NUM_LIBRARIES 16

// Arduino debug trace
class _Arduino {
public:
    static void pinMode(byte pin, byte value);
    static void digitalWrite(byte pin, byte value);
    static byte digitalRead(byte pin);
    static void analogWrite(byte pin, byte value);
    static int  analogRead(byte pin);
    static void tone(byte pin, unsigned int frequency, unsigned long duration);
    static byte noTone(byte pin);
};

class MWArduinoClass
{ 
public:
    void pinModeMW(byte pin, byte value);
    void digitalWriteMW(byte pin, byte value);
	byte digitalReadMW(byte pin);
	void analogWriteMW(byte pin, byte value);
	int analogReadMW(byte pin);
	void toneMW(byte pin, unsigned int frequency, unsigned long duration);

public:
	LibraryBase* libraryArray[MAX_NUM_LIBRARIES];
	
public:
	MWArduinoClass();
    void begin(long);
    void update();
	void registerLibrary(LibraryBase* lib);
};

extern MWArduinoClass MWArduino;

#endif // MWArduino.h

