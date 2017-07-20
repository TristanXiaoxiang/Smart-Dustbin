/*
  MWArduino.cpp - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
 
  See file LICENSE.txt for licensing terms.
*/

#include "MWArduino.h"

extern "C" {
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>
}

int freeRam () {
  extern int __heap_start, *__brkval; 
  int v; 
  return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}

// String formatting- variable-length inputs
//
#ifdef MW_DEBUG
byte isTraceOn = 0x00;
void _p(char *fmt, ... ){
    	Serial.flush();
        char tmp[256]; // resulting string limited to 256 chars
        
        char fmt_char[256];
        char c;
        byte i = 0;
        while((c = pgm_read_byte(fmt++)) && i < 255){
            fmt_char[i] = c;
            i++;
        }
        fmt_char[i] = 0; // add 0 in the end to indicate end of string
        
        va_list args;
        va_start (args, fmt);
        vsnprintf(tmp, 256, fmt_char, args);
        va_end (args);
        
        byte count = strlen(tmp);
        
        /*
        char availableRAM [11];
        sprintf(availableRAM, "RAM: %d\n", freeRam()+11);
        byte additional_count = strlen(availableRAM);
        
        // format of debug message is count, e.g number of chars, followed by the message
        Serial.write(uint8_t(0)); // MW header
        Serial.write(uint8_t(1)); // msgID: 0 - non debug msg; 1 - debug msg
        Serial.write(count + additional_count);
        Serial.print(tmp);
        Serial.print(availableRAM);
		Serial.flush();
        */
        
        // format of debug message is count, e.g number of chars, followed by the message
        Serial.write(uint8_t(0)); // MW header
        Serial.write(uint8_t(1)); // msgID: 0 - non debug msg; 1 - debug msg
        Serial.write(count);
        Serial.print(tmp);
		Serial.flush();
}
#else
byte isTraceOn = 0x01;
void _p(char *fmt, ... ){
    // do nothing
}
#endif

#define STR_EXPAND(tok) #tok
#define STR(tok) STR_EXPAND(tok)

/* Store static debug message strings in flash to avoid running out of SRAM memory */
#include <avr/pgmspace.h>

//prog_char MSG_BASE_SYSEX[] 			              PROGMEM = "\nArduino::commandHandler: command %d, sequence_ID %d, payload_size %d, %d, cmdID %d, params %d, %d\n";
//prog_char MSG_ADDON_SYSEX[] 		  			  PROGMEM = "\nLibrary::commandHandler: command %d, sequence_ID %d, payload_size %d, %d, libraryID %d, cmdID %d, params %d, %d\n";
//prog_char MSG_UNRECOGNIZED_SYSEX[] 	  			  PROGMEM = "Firmata::unrecognizedSysex: %d\n";
//prog_char MSG_MWARDUINO_GET_SERVER_INFO[]         PROGMEM = "MWArduino::getServerInfo();\n";
//prog_char MSG_MWARDUINO_GET_AVAILABLE_RAM[]       PROGMEM = "MWArduino::getAvailableRAM() --> %d;\n";

void sendResponseMsg(byte cmdID, int payload_size, byte* val){ 
// returning message format: 0, 0, cmdID, payload_size, value
    Serial.write(uint8_t(0)); // MW header
    Serial.write(uint8_t(0)); // msgID: 0 - non debug msg; 1 - debug msg
    Serial.write(cmdID);
    Serial.write((payload_size >> 8)); // msb
	Serial.write(payload_size & 0xff); // lsb
    for(int i = 0; i < payload_size; ++i){
        Serial.write(val[i]);
    }
    Serial.flush();
    
    // empty receive buffer
    while(Serial.available()){
        Serial.read();
    }
}

void ASCII2Binary(unsigned int count, byte* dataIn, byte* dataOut){
// Decode incoming ASCII arrays back into unit8 data
    byte startBit = 0;
    byte numASCIIs = 0;
    byte combinedVal = dataIn[0];
    for(unsigned int i = 0; i < count; ++i){
        startBit = i%7;
        byte lowerBitsVal = (combinedVal >> startBit) & (0x7f >> startBit);
        byte upperBitsVal = dataIn[numASCIIs+1] & (0x7f >> (7-startBit-1));
        dataOut[i] = lowerBitsVal + (upperBitsVal << (7-startBit));
        if(startBit == 6){
            numASCIIs++;
        }
        combinedVal = dataIn[++numASCIIs];
    }
}

// Callback functions
//
void sysexCallback(byte command, byte argc, byte *argv){
	if(command == 0x00){ // basic arduino and firmata commands
        //_p(MSG_BASE_SYSEX, command, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
		byte sequenceID = argv[0];
	    byte commandID = argv[3];
		switch(commandID){
            case 0x01:{ // getServerInfo
                //_p(MSG_MWARDUINO_GET_SERVER_INFO);
                
                byte val[256];
                
                // Board 
                char *board = STR(MW_BOARD);
                byte len = strlen(board);
                for(byte i = 0; i < len; i++){
                    val[i] = board[i];
                }
                val[len] = 0x3B;
                
                // TraceOn
                val[len+1] = isTraceOn;
                val[len+2] = 0x3B;
                
                // Libraries
                int count = len+3;
				for (byte i = 0; i < MAX_NUM_LIBRARIES; ++i) {
					if (MWArduino.libraryArray[i] != NULL){
                        val[count++] = i;
                        const char * libName = MWArduino.libraryArray[i]->getLibraryName();
                        byte len = strlen(libName);
                        for(byte j = 0; j < len; ++j){
                            val[count++] = libName[j];
                        }
                        if (MWArduino.libraryArray[i+1] != NULL){
                            val[count++] = 0x3B; // send ';' to seperate libraries
                        }
                    }
					else
						break;
				}
                val[count] = 0;
                sendResponseMsg(0x01, count, val);
                break;
            }
            case 0x02:{ // resetPinsState
                for(byte i = 2; i < TOTAL_PINS; ++i){
                    if(IS_PIN_DIGITAL(i)){
                        MWArduino.pinModeMW(i, OUTPUT);
                        MWArduino.digitalWriteMW(i, 0);
                        MWArduino.pinModeMW(i, INPUT);
                    }
                }
                sendResponseMsg(0x02, 0, 0);
				break;
            }
            case 0x03:{ // getAvailableRAM
                int availableRAM = freeRam();
                byte val[2];
                val[1] = availableRAM & 0xff; // lsb
                val[0] = availableRAM >> 8;   // msb
                //_p(MSG_MWARDUINO_GET_AVAILABLE_RAM, availableRAM);
        
                sendResponseMsg(0x03, 2, val);
				break;
            }
			case 0x10:{ // writeDigitalPin
				byte pin;
				int value;
		
				pin = argv[4];
				value = argv[5];
				MWArduino.digitalWriteMW(pin, value);
                
                sendResponseMsg(0x10, 0, 0);
				break;
			}
			case 0x11:{ // readDigitalPin
				byte pin;
				byte value;
				
				pin = argv[4];
                
				value = MWArduino.digitalReadMW(pin);
                
                sendResponseMsg(0x11, 1, &value);
				break;
			}
			case 0x12:{ // configureDigitalPin
				byte pin;
				byte value;
		
				pin = argv[4];
				value = argv[5];
				MWArduino.pinModeMW(pin, value);
                
                sendResponseMsg(0x12, 0, 0);
				break;
			}
			case 0x20: // writePWMVoltage
			case 0x21:{ // writePWMDutyCycle
				byte pin;
				int value;
		
				pin = argv[4];
                
                byte voltageBytes[2];
                ASCII2Binary(2, &argv[5], voltageBytes);
				value = voltageBytes[0]+(voltageBytes[1]<<8);
                
				MWArduino.analogWriteMW(pin, value);
                
                sendResponseMsg(0x21, 0, 0);
				break;
			}
			case 0x22:{ // playTone
				byte pin;
				unsigned int frequency;
				unsigned long duration;
                
				pin = argv[4];
                
                byte frequencyBytes[2];
                ASCII2Binary(2, &argv[5], frequencyBytes);
                frequency = frequencyBytes[0]+(frequencyBytes[1]<<8); // unsigned int
                
                byte durationBytes[2];
                ASCII2Binary(2, &argv[8], durationBytes);
                duration = durationBytes[0]+(durationBytes[1]<<8); // unsigned long
                
				MWArduino.toneMW(pin, frequency, duration);
                
                sendResponseMsg(0x22, 0, 0);
				break;
			}
			case 0x30:{ // readVoltage
				byte pin;
				int value;
				
				pin = argv[4];
				value = MWArduino.analogReadMW(pin);
                
                byte val[2];
                val[0] = (value >> 8) & 0x03;
                val[1] = value & 0xff;
                sendResponseMsg(0x30, 2, val);
				break;
			}
			default:
				break;
		}
	}
	else if(command == 0x01){
	     // add-on library commands
		 // command is actually libraryID, which is also the index
        //_p(MSG_ADDON_SYSEX, command, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
        byte libraryID = argv[3];
        if (MWArduino.libraryArray[libraryID] != NULL){
            MWArduino.libraryArray[libraryID]->commandHandler(argv);
        }
	}
    else{
        //_p(MSG_UNRECOGNIZED_SYSEX, command);
    }

	//Serial.write(10); // ACK - LF/CR
	//Serial.write(13); 
}

// MWArduino class
//
MWArduinoClass::MWArduinoClass()
{
  //firmwareVersionCount = 0;
  //systemReset();

  for (byte i = 0; i < MAX_NUM_LIBRARIES; ++i) {
	libraryArray[i] = NULL;
  }
}

void MWArduinoClass::pinModeMW(byte pin, byte value) {
    byte pinIndex = PIN_TO_DIGITAL(pin);
    _Arduino::pinMode(pinIndex, value);
}

void MWArduinoClass::digitalWriteMW(byte pin, byte value)
{
	_Arduino::digitalWrite(pin, value);
}

byte MWArduinoClass::digitalReadMW(byte pin)
{
    return _Arduino::digitalRead(pin);
}

void MWArduinoClass::analogWriteMW(byte pin, byte value)
{
	_Arduino::analogWrite(pin, value);
}

int MWArduinoClass::analogReadMW(byte pin)
{
	return _Arduino::analogRead(pin);;
}

void MWArduinoClass::toneMW(byte pin, unsigned int frequency, unsigned long duration)
{
    #ifdef ARDUINO_ARCH_AVR
	if (frequency == 0 || duration == 0) {
		_Arduino::noTone(pin);
	}
	else {
		_Arduino::tone(pin, frequency, duration);
	}
    #endif
}

void MWArduinoClass::begin(long speed) 
{
    Firmata.setFirmwareNameAndVersion("ArduinoServer IO Library", FIRMATA_MAJOR_VERSION, FIRMATA_MINOR_VERSION);
	Firmata.attach(START_SYSEX, sysexCallback);

    Firmata.begin(speed);
}

void MWArduinoClass::update()
{
    while(Firmata.available()) {
        Firmata.processInput();
    }
}

void MWArduinoClass::registerLibrary(LibraryBase* lib)
{
	for (byte i = 0; i < MAX_NUM_LIBRARIES; ++i) {
		if (libraryArray[i]==NULL) {
			libraryArray[i] = lib;
			return;
		}
	}
}


// Arduino debug trace
//
//
prog_char MSG_MWARDUINOCLASS_DIGITAL_WRITE[]      PROGMEM = "Arduino::digitalWrite(%d, %s);\n";
prog_char MSG_MWARDUINOCLASS_DIGITAL_READ[]  	  PROGMEM = "Arduino::digitalRead(%d); --> %s\n";
prog_char MSG_MWARDUINOCLASS_PIN_MODE[]  	  	  PROGMEM = "Arduino::pinMode(%d, %s);\n";
prog_char MSG_MWARDUINOCLASS_ANALOG_WRITE[]  	  PROGMEM = "Arduino::analogWrite(%d, %d);\n";
prog_char MSG_MWARDUINOCLASS_ANALOG_READ[] 		  PROGMEM = "Arduino::analogRead(%d) --> %d;\n";
prog_char MSG_MWARDUINOCLASS_PLAY_TONE[]   		  PROGMEM = "Arduino::playTone(%d, %d, %d);\n";
prog_char MSG_MWARDUINOCLASS_NO_TONE[]   		  PROGMEM = "Arduino::noTone(%d);\n";

void _Arduino::pinMode(byte pin, byte value) {
	switch (value) {
	case INPUT:
		_p(MSG_MWARDUINOCLASS_PIN_MODE, pin, "INPUT");
		break;
	case OUTPUT:
		_p(MSG_MWARDUINOCLASS_PIN_MODE, pin, "OUTPUT");
		break;
	case INPUT_PULLUP:
		_p(MSG_MWARDUINOCLASS_PIN_MODE, pin, "INPUT_PULLUP");
		break;
	default:
		char szBuffer[8];
		_p(MSG_MWARDUINOCLASS_PIN_MODE, pin, itoa(value, szBuffer, 10));
		break;
	}
    ::pinMode(pin, value);
}

void _Arduino::digitalWrite(byte pin, byte value) {
	switch (value) {
	case HIGH:
		_p(MSG_MWARDUINOCLASS_DIGITAL_WRITE, pin, "HIGH");
		break;
	case LOW:
		_p(MSG_MWARDUINOCLASS_DIGITAL_WRITE, pin, "LOW");
		break;
	default:
		char szBuffer[8];
		_p(MSG_MWARDUINOCLASS_DIGITAL_WRITE, pin, itoa(value, szBuffer, 10));
		break;
	}
	::digitalWrite(pin, value);
}

byte _Arduino::digitalRead(byte pin) {
    byte value = ::digitalRead(pin);
	switch (value) {
	case HIGH:
		_p(MSG_MWARDUINOCLASS_DIGITAL_READ, pin, "HIGH");
		break;
	case LOW:
		_p(MSG_MWARDUINOCLASS_DIGITAL_READ, pin, "LOW");
		break;
	default:
		char szBuffer[8];
		_p(MSG_MWARDUINOCLASS_DIGITAL_READ, pin, itoa(value, szBuffer, 10));
		break;
	}
    return value;
}

void _Arduino::analogWrite(byte pin, byte value) {
    _p(MSG_MWARDUINOCLASS_ANALOG_WRITE, pin, value);
	::analogWrite(pin, value);
}

int _Arduino::analogRead(byte pin) {
    int value = ::analogRead(pin);
    _p(MSG_MWARDUINOCLASS_ANALOG_READ, pin, value);
    return value;
}

void _Arduino::tone(byte pin, unsigned int frequency, unsigned long duration) {
    #ifdef ARDUINO_ARCH_SAM
    #else
    _p(MSG_MWARDUINOCLASS_PLAY_TONE, pin, frequency, duration);
	::tone(pin, frequency, duration);
    #endif
}

byte _Arduino::noTone(byte pin) {
    #ifdef ARDUINO_ARCH_SAM
    #else
    _p(MSG_MWARDUINOCLASS_NO_TONE, pin);
    ::noTone(pin);
    #endif
}

//
//
//
#include "Dynamic.cpp"
//
//
//
