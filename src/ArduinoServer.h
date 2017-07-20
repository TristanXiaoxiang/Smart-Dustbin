/*
  MWArduino.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
 
  See file LICENSE.txt for licensing terms.
*/

#ifndef ArduinoServer_h
#define ArduinoServer_h

#include "Dynamic.h"

enum FIRMATA_PINMODE { 
    PM_INPUT = 0,    
    PM_OUTPUT,    
    PM_ANALOG,    
    PM_PWM,    
    PM_SERVO 
};

class ArduinoServer
{
private:
    byte previousPIN[TOTAL_ANALOG_PINS];  // Use to store analog pin values
    byte previousPORT[TOTAL_PORTS]; // Use to store digital pin values

public:
    static void setPinMode(byte pin, int firmata_pinmode);
    static void digitalWrite(byte port, int value);
    static byte digitalRead(byte port);
    static void analogWrite(byte pin, int degrees);
    static int analogRead(byte pin);  
public:
	ArduinoServer();
    void begin(long);
    void update();    
};

extern ArduinoServer MWArduino;

#endif // ArduinoServer.h

