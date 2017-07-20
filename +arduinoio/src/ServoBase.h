/*
  ServoBase.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
*/
#include "Servo.h"
#include "LibraryBase.h"

#include "MWArduino.h"

//prog_char MSG_SERVO_ENTER_COMMAND_HANDLER[] 	PROGMEM = "ServoBase::commandHandler: sequence_ID %d, payload_size %d, %d, libraryID %d, servoID %d, cmdID %d\n";
//prog_char MSG_SERVO_UNRECOGNIZED_COMMAND[] 		PROGMEM = "ServoBase::commandHandler:unrecognized command ID %d\n";

// Arduino trace commands
prog_char MSG_SERVO_NEW[] 			            PROGMEM = "Arduino::servoArray[%d] = new Servo; --> 0x%04X\n";
prog_char MSG_SERVO_DELETE[]     	            PROGMEM = "Arduino::delete servoArray[%d]\nArduino:servoArray[%d] = NULL;\n";
prog_char MSG_SERVO_ATTACH[] 			        PROGMEM = "Arduino::servoArray[%d]->attach(%d, %d, %d)\n";
prog_char MSG_SERVO_DETACH[]			        PROGMEM = "Arduino::servoArray[%d]->detach()\n";
prog_char MSG_SERVO_READ[]			            PROGMEM = "Arduino::servoArray[%d]->read(); --> %d\n";
prog_char MSG_SERVO_WRITE[]			            PROGMEM = "Arduino::servoArray[%d]->write(%d);\n";

Servo *servoArray[MAX_SERVOS];

class _Servo {
public:
    static void _new(byte servoID) {
        servoArray[servoID] = new Servo;
        _p(MSG_SERVO_NEW, servoID, servoArray[servoID]);
    }

    static void _delete(byte servoID) {
        delete servoArray[servoID];
        servoArray[servoID] = NULL;
        _p(MSG_SERVO_DELETE, servoID, servoID);
    }

    static void attach(byte servoID, byte pin, int min, int max) {
        servoArray[servoID]->attach(pin, min, max);
        _p(MSG_SERVO_ATTACH, servoID, pin, min, max);
    }

    static void detach(byte servoID) {
        servoArray[servoID]->detach();
        _p(MSG_SERVO_DETACH, servoID);
    }

    static byte read(byte servoID) {
        byte angle = servoArray[servoID]->read();
        _p(MSG_SERVO_READ, servoID, angle);
        return angle;
    }

    static void write(byte servoID, byte angle) {
        servoArray[servoID]->write(angle);
        _p(MSG_SERVO_WRITE, servoID, angle);
    }
};

class ServoBase : public LibraryBase
{
	private: 
		const char* libName;
	public:
		ServoBase(MWArduinoClass& a) : libName("Servo")
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
            //_p(MSG_SERVO_ENTER_COMMAND_HANDLER, command[0], command[1], command[2], command[3], command[4], command[5]);
            byte sequenceID = command[0];
            byte cmdID = command[5];
            switch (cmdID){
                case 0x00:{  // createServo
                    byte servoID = command[4];
                    byte pin = command[6];
                    
                    byte minBytes[2];
                    ASCII2Binary(2, &command[7], minBytes);
                    int min = minBytes[0]+(minBytes[1]<<8);
                    byte maxBytes[2];
                    ASCII2Binary(2, &command[10], maxBytes);
                    int max = maxBytes[0]+(maxBytes[1]<<8);
                    

                    _Servo::_new(servoID);
                    _Servo::attach(servoID, pin, min, max);
                    
                    sendResponseMsg(0x00, 0, 0);
                    break;
                }
                case 0x01:{ // clearServo
                    byte servoID = command[4];
                    _Servo::detach(servoID);
                    _Servo::_delete(servoID);
                    
                    sendResponseMsg(0x01, 0, 0);
                    break;
                }
                case 0x02:{ // readPosition
                    byte servoID = command[4];
                    byte angle = _Servo::read(servoID);
                    
                    byte val[1] = {angle};
                    sendResponseMsg(0x02, 1, val);
                    break;
                }
                case 0x03:{ // writePosition
                    byte servoID = command[4];
                    
                    byte angle;
                    ASCII2Binary(1, &command[6], &angle);
                    _Servo::write(servoID, angle);
                    
                    sendResponseMsg(0x03, 0, 0);
                    break;
                }
                default:
                    //_p(MSG_SERVO_UNRECOGNIZED_COMMAND, cmdID);
					break;
            }
		}
};