/*
  SPIBase.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
*/
#include "SPI.h"
#include "LibraryBase.h"

#include "MWArduino.h"

//prog_char MSG_SPI_ENTER_COMMAND_HANDLER[] 	PROGMEM = "SPIBase::commandHandler: sequence_ID %d, payload_size %d, %d, libraryID %d, cmdID %d\n";
//prog_char MSG_SPI_UNRECOGNIZED_COMMAND[] 	PROGMEM = "SPIBase::commandHandler:unrecognized command ID %d\n";
        
// Arduino trace commands
prog_char MSG_SPI_BEGIN[]                   PROGMEM = "Arduino::SPI.begin();\n";
prog_char MSG_SPI_BEGIN_DUE[]               PROGMEM = "Arduino::SPI.begin(%d);\n";
prog_char MSG_SPI_SETCLOCKDIVIDER[]         PROGMEM = "Arduino::SPI.setClockDivider(%s);\n";
prog_char MSG_SPI_SETCLOCKDIVIDER_DUE[]     PROGMEM = "Arduino::SPI.setClockDivider(%d, %d);\n";
prog_char MSG_SPI_END[]                     PROGMEM = "Arduino::SPI.end();\n";
prog_char MSG_SPI_END_DUE[]                 PROGMEM = "Arduino::SPI.end(%d);\n";
prog_char MSG_SPI_SETDATAMODE[]             PROGMEM = "Arduino::SPI.setDataMode(%s);\n";
prog_char MSG_SPI_SETDATAMODE_DUE[]         PROGMEM = "Arduino::SPI.setDataMode(%d, %s);\n";
prog_char MSG_SPI_SETBITORDER[]             PROGMEM = "Arduino::SPI.setBitOrder(%s);\n";
prog_char MSG_SPI_SETBITORDER_DUE[]         PROGMEM = "Arduino::SPI.setBitOrder(%d, %s);\n";
prog_char MSG_SPI_TRANSFER[]                PROGMEM = "Arduino::SPI.Transfer(%d); --> %d\n";
prog_char MSG_SPI_TRANSFER_DUE[]            PROGMEM = "Arduino::SPI.Transfer(%d, %d, %d); --> %d\n";

class _SPI {
public:
    #ifdef ARDUINO_ARCH_SAM
    static void begin(byte cspin) {
        _Arduino::pinMode(cspin, OUTPUT);
        SPI.begin(cspin);
        _p(MSG_SPI_BEGIN_DUE, cspin);
    }

    static void end(byte cspin) {
        SPI.end(cspin);
        _p(MSG_SPI_END_DUE, cspin);
    }
	
	static void setClockDivider(byte cspin, byte divider) {
        SPI.setClockDivider(cspin, divider);
		_p(MSG_SPI_SETCLOCKDIVIDER_DUE, cspin, divider);
    }

    static void setDataMode(byte cspin, byte mode) {
        SPI.setDataMode(cspin, mode);
		switch (mode) {
			case SPI_MODE0:
				_p(MSG_SPI_SETDATAMODE_DUE, cspin, "SPI_MODE0");
				break;
			case SPI_MODE1:
				_p(MSG_SPI_SETDATAMODE_DUE, cspin, "SPI_MODE1");
				break;
			case SPI_MODE2:
				_p(MSG_SPI_SETDATAMODE_DUE, cspin, "SPI_MODE2");
				break;
			case SPI_MODE3:
				_p(MSG_SPI_SETDATAMODE_DUE, cspin, "SPI_MODE3");
				break;
			default:
				char szBuffer[8];
				_p(MSG_SPI_SETDATAMODE_DUE, cspin, itoa(mode, szBuffer, 10));
				break;
		}
    }
	
	static void setBitOrder(byte cspin, BitOrder order) {
        SPI.setBitOrder(cspin, order);
		switch (order) {
			case MSBFIRST:
				_p(MSG_SPI_SETBITORDER_DUE, cspin, "MSBFIRST");
				break;
			case LSBFIRST:
				_p(MSG_SPI_SETBITORDER_DUE, cspin, "LSBFIRST");
				break;
			default:
				char szBuffer[8];
				_p(MSG_SPI_SETBITORDER_DUE, cspin, itoa(order, szBuffer, 10));
				break;
		}
    }

    static byte transfer(byte cspin, byte val, SPITransferMode transferMode = SPI_LAST) {
        byte dataRead = SPI.transfer(cspin, val, transferMode);
        _p(MSG_SPI_TRANSFER_DUE, cspin, val, transferMode, dataRead);
        return dataRead;
    }

    #else

    static void begin(byte cspin) {
        _Arduino::pinMode(cspin, OUTPUT);
        SPI.begin();
        _p(MSG_SPI_BEGIN);
    }

    static void end(byte cspin) {
        SPI.end();
        _p(MSG_SPI_END);
    }
	
	static void setClockDivider(byte divider) {
        SPI.setClockDivider(divider);
		switch (divider) {
			case SPI_CLOCK_DIV2:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV2");
				break;
			case SPI_CLOCK_DIV4:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV4");
				break;
			case SPI_CLOCK_DIV8:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV8");
				break;
			case SPI_CLOCK_DIV16:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV16");
				break;
			case SPI_CLOCK_DIV32:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV32");
				break;
			case SPI_CLOCK_DIV64:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV64");
				break;
			case SPI_CLOCK_DIV128:
				_p(MSG_SPI_SETCLOCKDIVIDER, "SPI_CLOCK_DIV128");
				break;
			default:
				char szBuffer[8];
				_p(MSG_SPI_SETCLOCKDIVIDER, itoa(divider, szBuffer, 10));
				break;
		}
    }

    static void setDataMode(byte mode) {
        SPI.setDataMode(mode);
        switch (mode) {
			case SPI_MODE0:
				_p(MSG_SPI_SETDATAMODE, "SPI_MODE0");
				break;
			case SPI_MODE1:
				_p(MSG_SPI_SETDATAMODE, "SPI_MODE1");
				break;
			case SPI_MODE2:
				_p(MSG_SPI_SETDATAMODE, "SPI_MODE2");
				break;
			case SPI_MODE3:
				_p(MSG_SPI_SETDATAMODE, "SPI_MODE3");
				break;
			default:
				char szBuffer[8];
				_p(MSG_SPI_SETDATAMODE, itoa(mode, szBuffer, 10));
				break;
		}
    }

    static void setBitOrder(byte order) {
        SPI.setBitOrder(order);
        switch (order) {
			case MSBFIRST:
				_p(MSG_SPI_SETBITORDER, "MSBFIRST");
				break;
			case LSBFIRST:
				_p(MSG_SPI_SETBITORDER, "LSBFIRST");
				break;
			default:
				char szBuffer[8];
				_p(MSG_SPI_SETBITORDER, itoa(order, szBuffer, 10));
				break;
		}
    }

    static byte transfer(byte val) {
        byte dataRead = SPI.transfer(val);
        _p(MSG_SPI_TRANSFER, val, dataRead);
        return dataRead;
    }

    #endif
};

class SPIBase : public LibraryBase
{
	private: 
		const char* libName;
		
	public:
		SPIBase(MWArduinoClass& a) : libName("SPI")
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
            //_p(MSG_SPI_ENTER_COMMAND_HANDLER, command[0], command[1], command[2], command[3], command[4]);
            byte sequenceID = command[0];
            byte cmdID = command[4];
            switch (cmdID){
                case 0x00:{  // startSPI
                    byte cspin = command[5];
                    
					#ifdef ARDUINO_ARCH_SAM
                    _SPI::setClockDivider(cspin, 21);
                    #else
                    _SPI::setClockDivider(SPI_CLOCK_DIV4);
                    #endif
					
                    _SPI::begin(cspin);
                    
                    sendResponseMsg(0x00, 0, 0);
                    break;
                }
                case 0x01:{ // stopSPI
                    byte cspin = command[5];
                    
                    _SPI::end(cspin);
                    
                    sendResponseMsg(0x01, 0, 0);
                    break;
                }
                case 0x02:{ // setDataMode
                    byte cspin = command[5];
                    byte mode = command[6];
                    
                    #ifdef ARDUINO_ARCH_SAM
                    _SPI::setDataMode(cspin, mode);
                    #else
                    _SPI::setDataMode(mode);
                    #endif
                    
                    sendResponseMsg(0x02, 0, 0);
                    break;
                }
                case 0x03:{ // setBitOrder
                    byte cspin = command[5];
                    byte order = command[6];
                    
                    #ifdef ARDUINO_ARCH_SAM
                    _SPI::setBitOrder(cspin, BitOrder(order));
                    #else
                    _SPI::setBitOrder(order);
                    #endif
                    
                    sendResponseMsg(0x03, 0, 0);
                    break;
                }
                case 0x04:{ // writeRead
                    byte cspin = command[5];
                    
                    byte len;
                    ASCII2Binary(1, &command[6], &len);

                    byte dataRead;
                    byte dataToSend;

                    byte* val = new byte [len];
                    for(byte i = 0; i < len; ++i){
                        ASCII2Binary(len, &command[8], val);
                    }
                    
                    #ifdef ARDUINO_ARCH_SAM
                    for(byte i = 0; i < len-1; ++i){
                        dataToSend = val[i];
                        dataRead = _SPI::transfer(cspin, dataToSend, SPI_CONTINUE);
                        val[i] = dataRead;
                    }
                    dataToSend = val[len-1];
                    dataRead = _SPI::transfer(cspin, dataToSend);
                    val[len-1] = dataRead;
                    #else
                    _Arduino::digitalWrite(cspin, LOW);
                    for(byte i = 0; i < len; ++i){
                        dataToSend = val[i];
                        dataRead = _SPI::transfer(dataToSend);
                        val[i] = dataRead;
                    }
                    _Arduino::digitalWrite(cspin, HIGH);
                    #endif
                    
                    sendResponseMsg(0x04, len, val);
                    delete [] val;
                    break;
                }
                default:
                    //_p(MSG_SPI_UNRECOGNIZED_COMMAND, cmdID);
					break;
            }
		}
};