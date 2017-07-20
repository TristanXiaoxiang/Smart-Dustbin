/*
  I2CBase.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
*/
#include "Wire.h"
#include "LibraryBase.h"

#include "MWArduino.h"

//prog_char MSG_I2C_ENTER_COMMAND_HANDLER[] 	PROGMEM = "I2CBase::commandHandler: sequence_ID %d, payload_size %d, %d, libraryID %d, cmdID %d\n";
//prog_char MSG_I2C_UNRECOGNIZED_COMMAND[] 	PROGMEM = "I2CBase::commandHandler:unrecognized command ID %d\n";
//prog_char MSG_I2C_SCAN_BUS[]                PROGMEM = "scanI2CBus(%d)\n";
//prog_char MSG_I2C_READ_PARAMS[]             PROGMEM = ", params %d, %d, %d\n";
//prog_char MSG_I2C_WRITE_PARAMS[]            PROGMEM = ", params %d, %d, %d\n";
//prog_char MSG_I2C_READ_REGISTER_PARAMS[]    PROGMEM = ", params %d, %d, %d, %d\n";
//prog_char MSG_I2C_READ_VALUES[]             PROGMEM = "Read value: %d\n";
//prog_char MSG_I2C_WRITE_REGISTER_PARAMS[]   PROGMEM = ", params %d, %d, %d, %d, values ";
//prog_char MSG_I2C_WRITE_VALUES[]            PROGMEM = "%d, ";

// Arduino trace commands
prog_char MSG_WIRE_BEGIN[]                  PROGMEM = "Arduino::Wire.begin();\n";
prog_char MSG_WIRE_BEGINTRANSMISSION[]      PROGMEM = "Arduino::Wire.beginTransmission(%d);\n";
prog_char MSG_WIRE_ENDTRANSMISSION[]        PROGMEM = "Arduino::Wire.endTransmission(%d); --> %d\n";
prog_char MSG_WIRE_READ[]                   PROGMEM = "Arduino::Wire.read(); --> %d\n";
prog_char MSG_WIRE_WRITE[]                  PROGMEM = "Arduino::Wire.write(%d); --> %d\n";
prog_char MSG_WIRE_WRITE2_1[]               PROGMEM = "Arduino::Wire.write([%d], %d); --> %d\n";
prog_char MSG_WIRE_WRITE2_2[]               PROGMEM = "Arduino::Wire.write([%d, %d], %d); --> %d\n";
prog_char MSG_WIRE_WRITE2_3[]               PROGMEM = "Arduino::Wire.write([%d, %d, %d,...], %d); --> %d\n";
prog_char MSG_WIRE_REQUESTFROM[]            PROGMEM = "Arduino::Wire.requestFrom(%d, %d, %d); --> %d\n";
prog_char MSG_WIRE1_BEGIN[]                 PROGMEM = "Arduino::Wire1.begin();\n";
prog_char MSG_WIRE1_BEGINTRANSMISSION[]     PROGMEM = "Arduino::Wire1.beginTransmission(%d);\n";
prog_char MSG_WIRE1_ENDTRANSMISSION[]       PROGMEM = "Arduino::Wire1.endTransmission(%d); --> %d\n";
prog_char MSG_WIRE1_READ[]                  PROGMEM = "Arduino::Wire1.read(); --> %d\n";
prog_char MSG_WIRE1_WRITE[]                 PROGMEM = "Arduino::Wire1.write(%d); --> %d\n";
prog_char MSG_WIRE1_WRITE2_1[]              PROGMEM = "Arduino::Wire1.write([%d], %d); --> %d\n";
prog_char MSG_WIRE1_WRITE2_2[]              PROGMEM = "Arduino::Wire1.write([%d, %d], %d); --> %d\n";
prog_char MSG_WIRE1_WRITE2_3[]              PROGMEM = "Arduino::Wire1.write([%d, %d, %d, ...], %d); --> %d\n";
prog_char MSG_WIRE1_REQUESTFROM[]           PROGMEM = "Arduino::Wire1.requestFrom(%d, %d, %d); --> %d\n";


bool hasBegin[2] = {false, false};

class _Wire {
public:
    static void begin() {
        _p(MSG_WIRE_BEGIN);
        Wire.begin();
    }

    static void beginTransmission(int address) {
        _p(MSG_WIRE_BEGINTRANSMISSION, address);
        Wire.beginTransmission(address);
    }

    static byte endTransmission(byte stop = true) {
        byte status = Wire.endTransmission(stop);
        _p(MSG_WIRE_ENDTRANSMISSION, stop, status);
        return status;
    }

    static byte requestFrom(int address, int quantity, int stop = true) {
        byte status = Wire.requestFrom(address, quantity, stop);
        _p(MSG_WIRE_REQUESTFROM, address, quantity, stop, status);
        return status;
    }

    static int read() {
        int value = Wire.read();
        _p(MSG_WIRE_READ, value);
        return value;
    }

    static size_t write(byte value) {
        size_t n = Wire.write(value);
        _p(MSG_WIRE_WRITE, value, n);
        return n;
    }

    static size_t write(byte* value, size_t length) {
        size_t n = Wire.write(value, length);
		switch (length) {
		case 1:
			_p(MSG_WIRE_WRITE2_1, value[0], length, n);
			break;
		case 2:
			_p(MSG_WIRE_WRITE2_2, value[0], value[1], length, n);
			break;
		default:
			_p(MSG_WIRE_WRITE2_3, value[0], value[1], value[2], length, n);
			break;
		}
        return n;
    }
};

class _Wire1 {
public:
    static void begin() {
        #ifdef ARDUINO_ARCH_SAM
        _p(MSG_WIRE1_BEGIN);
        Wire1.begin();
        #endif
    }

    static void beginTransmission(byte address) {
        #ifdef ARDUINO_ARCH_SAM
        _p(MSG_WIRE1_BEGINTRANSMISSION, address);
        Wire1.beginTransmission(address);
        #endif

    }

    static byte endTransmission(byte stop = true) {
        byte status = -1;
        #ifdef ARDUINO_ARCH_SAM
        status = Wire1.endTransmission(stop);
        _p(MSG_WIRE1_ENDTRANSMISSION, stop, status);
        #endif
        return status;
    }

    static byte requestFrom(int address, int quantity, int stop = true) {
        byte status = -1;
        #ifdef ARDUINO_ARCH_SAM
        status = Wire1.requestFrom(address, quantity, stop);
        _p(MSG_WIRE1_REQUESTFROM, address, quantity, stop, status);
        #endif
        return status;
    }

    static int read() {
        int value = -1;
        #ifdef ARDUINO_ARCH_SAM
        value = Wire1.read();
        _p(MSG_WIRE1_READ, value);
        #endif
        return value;
    }

    static size_t write(byte value) {
        size_t n = -1;
        #ifdef ARDUINO_ARCH_SAM
        n = Wire1.write(value);
        _p(MSG_WIRE1_WRITE, value, n);
        #endif
        return n;
    }

    static size_t write(byte* value, size_t lenght) {
        size_t n = -1;
        #ifdef ARDUINO_ARCH_SAM
        n = Wire1.write(value, lenght);
        switch (lenght) {
		case 1:
			_p(MSG_WIRE1_WRITE2_1, value[0], lenght, n);
			break;
		case 2:
			_p(MSG_WIRE1_WRITE2_2, value[0], value[1], lenght, n);
			break;
		default:
			_p(MSG_WIRE1_WRITE2_3, value[0], value[1], value[3], lenght, n);
			break;
		}
        #endif
        return n;
    }
};

class I2CBase : public LibraryBase
{
	private: 
		const char* libName;
		
	public:
		I2CBase(MWArduinoClass& a) : libName("I2C")
		{
			a.registerLibrary(this);
		}
		
	// Implementation of LibraryBase
	//
	public:
		const char* getLibraryName() const 
		{
			return libName;
		}
	
		void commandHandler(byte* command)
		{
            //_p(MSG_I2C_ENTER_COMMAND_HANDLER, command[0], command[1], command[2], command[3], command[4]);
            byte sequenceID = command[0];
            byte cmdID = command[4];
            switch (cmdID){
                case 0x00:{  // startI2C
                    byte bus = command[5];
                    byte address = command[6];
                    
                    if(hasBegin[bus] == false){
                        if(bus == 0){
                            _Wire::begin();
                        }
                        else{ // For now, only bus 0 and 1 are supported
                            #ifdef ARDUINO_ARCH_SAM
                            _Wire1::begin();
                            #endif
                        }
                        hasBegin[bus] = true;
                    }
                    
                    sendResponseMsg(0x00, 0, 0);
                    break;
                }
                case 0x01:{ // scanI2CBus
                    //_p(MSG_I2C_SCAN_BUS, command[5]);
                    byte bus      = command[5];
                    
                    if(hasBegin[bus] == false){
                        if(bus == 0){
                            _Wire::begin();
                        }
                        else{
                            #ifdef ARDUINO_ARCH_SAM
                            _Wire1::begin();
                            #endif
                        }
                        hasBegin[bus] = true;
                    }
                    
                    byte val[112];
                    byte count = 0;
                    for(byte addr = 8; addr < 120; ++addr){
                        if(bus == 0){
                            _Wire::beginTransmission(addr);
                            byte code = _Wire::endTransmission();
                            
                            if(code == 0){
                                val[count++] = addr;
                            }
                        }
                        else{
                            #ifdef ARDUINO_ARCH_SAM
                            _Wire1::beginTransmission(addr);
                            byte code = _Wire1::endTransmission();
                            
                            if(code == 0){
                                val[count++] = addr;
                            }
                            #endif
                        }
                    }
                    if(count == 0){
                        val[0] = 0;
                    }
                    sendResponseMsg(0x01, count, val);
                    break;
                }
                case 0x02:{ // read
                    //_p(MSG_I2C_READ_PARAMS, command[5], command[6], command[7]);
                    byte bus      = command[5];
                    byte address  = command[6];
                    
                    byte numBytes; // numBytes can only be a byte according to requestFrom API prototype
                    ASCII2Binary(1, &command[7], &numBytes); 
                    
                    byte dataRead;
                    
                    byte* val = new byte [numBytes+1];
                    
                    if(bus == 0){
                        _Wire::beginTransmission(address);
                        if(_Wire::requestFrom(address, (uint8_t)numBytes) != numBytes){
                            val[0] = 0xFF;
                        }
                        else{
                            val[0] = 0x00;
                            for(byte i = 1; i < numBytes+1; ++i){
                                val[i] = _Wire::read();
                            }
                        }
                        _Wire::endTransmission(true); 
                    }
                    else{
                        #ifdef ARDUINO_ARCH_SAM
                        _Wire1::beginTransmission(address);
                        if(_Wire1::requestFrom(address, (uint8_t)numBytes) != numBytes){
                            val[0] = 0xFF;
                        }
                        else{
                            val[0] = 0x00;
                            for(byte i = 1; i < numBytes+1; ++i){
                                val[i] = _Wire1::read();
                            }
                        }
                        _Wire1::endTransmission(false); 
                        #endif
                    }
                    
                    sendResponseMsg(0x02, numBytes+1, val);
                    
                    delete [] val;
                    break;
                }
                case 0x03:{ // write
                    //_p(MSG_I2C_WRITE_PARAMS, command[5], command[6], command[7]);
                    byte bus      = command[5];
                    byte address  = command[6];
                    
                    byte numBytes; // numBytes can only be a byte according to requestFrom API prototype
                    ASCII2Binary(1, &command[7], &numBytes); 
                    
                    byte* val = new byte [numBytes];
                    ASCII2Binary(numBytes, &command[9], val); 
                    for(byte i = 0; i < numBytes; ++i){
                        //_p(MSG_I2C_WRITE_VALUES, val[i]);
                    }
                    
                    if(bus == 0){
                        _Wire::beginTransmission(address);
                        _Wire::write(val, numBytes);
                        _Wire::endTransmission(true);
                    }
                    else{ // For now, only bus 0 and 1 are supported
                        #ifdef ARDUINO_ARCH_SAM
                        _Wire1::beginTransmission(address);
                        _Wire1::write(val, numBytes);
                        _Wire1::endTransmission(true);
                        #endif
                    }
                    
                    delete [] val;
                    
                    sendResponseMsg(0x03, 0, 0);
                    break;
                }
                case 0x04:{ // readRegister
                    //_p(MSG_I2C_READ_REGISTER_PARAMS, command[5], command[6], command[7], command[8]);
                    byte bus      = command[5];
                    byte address  = command[6];
                    
                    byte reg;
                    ASCII2Binary(1, &command[7], &reg);
                    byte numBytes = command[9];
                    byte dataRead;
                    
                    byte* val = new byte [numBytes+1];
                    
                    if(bus == 0){
                        _Wire::beginTransmission(address);
                        _Wire::write(reg);  
                        _Wire::endTransmission(false); 
                        if(_Wire::requestFrom(address, (uint8_t)numBytes) != numBytes){
                            val[0] = 0xFF;
                        }
                        else{
                            val[0] = 0x00;
                            for(byte i = 1; i < numBytes+1; ++i){
                                val[i] = _Wire::read();
                                //_p(MSG_I2C_READ_VALUES, val[i]);
                            }
                        }
                    }
                    else{
                        #ifdef ARDUINO_ARCH_SAM
                        _Wire1::beginTransmission(address);
                        _Wire1::write(reg);  
                        _Wire1::endTransmission(false); 
                        if(_Wire1::requestFrom(address, (uint8_t)numBytes) != numBytes){
                            val[0] = 0xFF;
                        }
                        else{
                            val[0] = 0x00;
                            for(byte i = 1; i < numBytes+1; ++i){
                                val[i] = _Wire1::read();
                            }
                        }
                        #endif
                    }
                    
                    sendResponseMsg(0x04, numBytes+1, val);
                    
                    delete [] val;
                    break;
                }
                case 0x05:{ // writeRegister
                    //_p(MSG_I2C_WRITE_REGISTER_PARAMS, command[5], command[6], command[7], command[8]);
                    byte bus      = command[5];
                    byte address  = command[6];
                    
                    byte reg;
                    ASCII2Binary(1, &command[7], &reg);
                    
                    byte numBytes = command[9];
                    
                    byte* val = new byte [numBytes];
                    ASCII2Binary(numBytes, &command[10], val);
                    for(byte i = 0; i < numBytes; ++i){
                        //_p(MSG_I2C_WRITE_VALUES, val[i]);
                    }
                    
                    if(bus == 0){
                        _Wire::beginTransmission(address);
                        _Wire::write(reg);
                        _Wire::write(val, numBytes);
                        _Wire::endTransmission(true);
                    }
                    else{ // For now, only bus 0 and 1 are supported
                        #ifdef ARDUINO_ARCH_SAM
                        _Wire1::beginTransmission(address);
                        _Wire1::write(reg);
                        _Wire1::write(val, numBytes);
                        _Wire1::endTransmission(true);
                        #endif
                    }
                    
                    delete [] val;
                    
                    sendResponseMsg(0x05, 0, 0);
                    break;
                }
                default:
                    //_p(MSG_I2C_UNRECOGNIZED_COMMAND, cmdID);
					break;
            }
		}
};