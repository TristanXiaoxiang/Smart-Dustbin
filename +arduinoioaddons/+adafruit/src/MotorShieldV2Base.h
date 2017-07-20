/*
  MotorShieldV1Base.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
*/
#include "LibraryBase.h"
#include "Adafruit_MotorShield.h"
#include "Adafruit_PWMServoDriver.h"
#include "MWArduino.h"

#define MIN_I2C 0x60
#define MAX_I2C 0x80

#if MW_BOARD == Uno
#define MAX_SHIELDS 4
#else
#define MAX_SHIELDS 32
#endif

#define MAX_DCMOTORS 4
#define MAX_STEPPERMOTORS 2

Adafruit_MotorShield *AFMS[MAX_SHIELDS];
Adafruit_DCMotor *DCMotors[MAX_SHIELDS][MAX_DCMOTORS];
Adafruit_StepperMotor *StepperMotors[MAX_SHIELDS][MAX_STEPPERMOTORS];

//prog_char MSG_MSV2_ENTER_COMMAND_HANDLER[]      PROGMEM = "MotorShieldV2Base::commandHandler: sequence_ID %d, payload_size %d, %d, libraryID %d, cmdID %d\n";
//prog_char MSG_MSV2_UNRECOGNIZED_COMMAND[]       PROGMEM = "MotorShieldV2Base::commandHandler:unrecognized command ID %d\n";
        
// Arduino trace commands
prog_char MSG_MSV2_CREATE_MOTOR_SHIELD[]        PROGMEM = "Adafruit::Adafruit_MotorShield(%d)->begin(%d);\n";
prog_char MSG_MSV2_DELETE_MOTOR_SHIELD[]        PROGMEM = "Adafruit::address %d;delete AFMS[%d];\n";
prog_char MSG_MSV2_CREATE_DC_MOTOR[]            PROGMEM = "Adafruit::address(%d);AFMS[%d]->getMotor(%d);\n";
prog_char MSG_MSV2_START_DC_MOTOR[]             PROGMEM = "Adafruit::DCMotors[%d][%d]->setSpeed(%d);\nDCMotors[%d][%d]->run(%d);\n";
prog_char MSG_MSV2_RELEASE_DC_MOTOR[]           PROGMEM = "Adafruit::DCMotors[%d][%d]->run(4);\n";
prog_char MSG_MSV2_SET_SPEED_DC_MOTOR[]         PROGMEM = "Adafruit::DCMotors[%d][%d]->setSpeed(%d);\nDCMotors[%d][%d]->run(%d);\n";
prog_char MSG_MSV2_CREATE_STEPPER_MOTOR[]       PROGMEM = "Adafruit::address(%d);AFMS[%d]->getStepper(%d, %d)-->0x%04X;\nStepperMotors[%d][%d]->setSpeed(%d);\n"; 
prog_char MSG_MSV2_MOVE_STEPPER_MOTOR[]         PROGMEM = "Adafruit::-->0x%04X;StepperMotors[%d][%d]->step(%d, %d, %d);\n";
prog_char MSG_MSV2_RELEASE_STEPPER_MOTOR[]      PROGMEM = "Adafruit::StepperMotors[%d][%d]->release();\n";
prog_char MSG_MSV2_SET_SPEED_STEPPER_MOTOR[]    PROGMEM = "Adafruit::StepperMotors[%d][%d]->setSpeed(%d);\n";


class _Adafruit_MotorShield {
public:
    // motorshield
    static void createMotorShield(byte i2caddress, unsigned int pwmfreq) {
        if(i2caddress >= MIN_I2C && i2caddress <= MAX_I2C){
            byte shieldnum = (i2caddress - MIN_I2C);
            AFMS[shieldnum] = new Adafruit_MotorShield(i2caddress);
            AFMS[shieldnum]->begin(pwmfreq);
            _p(MSG_MSV2_CREATE_MOTOR_SHIELD, i2caddress, pwmfreq);
        }
    }
    
    static void deleteMotorShield(byte i2caddress) {
        if(i2caddress >= MIN_I2C && i2caddress <= MAX_I2C){
            byte shieldnum = (i2caddress - MIN_I2C);
            delete AFMS[shieldnum];
            AFMS[shieldnum] = NULL;
            _p(MSG_MSV2_DELETE_MOTOR_SHIELD, i2caddress, shieldnum);
        }
    }
    
    // DC motor
    static void createDCMotor(byte i2caddress, byte motornum) {
            byte shieldnum = (i2caddress - MIN_I2C);
            DCMotors[shieldnum][motornum] = AFMS[shieldnum]->getMotor(motornum+1);
            _p(MSG_MSV2_CREATE_DC_MOTOR, i2caddress, shieldnum, motornum+1);
    }
    
    static void startDCMotor(byte i2caddress, byte motornum, unsigned int speed, byte direction) {
        byte shieldnum = (i2caddress - MIN_I2C);
        DCMotors[shieldnum][motornum]->setSpeed(speed);
        DCMotors[shieldnum][motornum]->run(direction);
        _p(MSG_MSV2_START_DC_MOTOR, shieldnum, motornum, speed, shieldnum, motornum, direction);
    }
    
    static void stopDCMotor(byte i2caddress, byte motornum) {
        byte shieldnum = (i2caddress - MIN_I2C);
        DCMotors[shieldnum][motornum]->run(4);
        _p(MSG_MSV2_RELEASE_DC_MOTOR, shieldnum, motornum);
    }

    static void setSpeedDCMotor(byte i2caddress, byte motornum, unsigned int speed, byte direction) {
        byte shieldnum = (i2caddress - MIN_I2C);
        DCMotors[shieldnum][motornum]->setSpeed(speed);
        DCMotors[shieldnum][motornum]->run(direction);
        _p(MSG_MSV2_SET_SPEED_DC_MOTOR, shieldnum, motornum, speed, shieldnum, motornum, direction);
    }

    // Stepper motor
    static void createStepperMotor(byte i2caddress, byte motornum, unsigned int sprev, unsigned int rpm) {
        byte shieldnum = (i2caddress - MIN_I2C);
        StepperMotors[shieldnum][motornum] = AFMS[shieldnum]->getStepper(sprev, motornum+1);
        StepperMotors[shieldnum][motornum]->setSpeed(rpm);
        _p(MSG_MSV2_CREATE_STEPPER_MOTOR, i2caddress, shieldnum, sprev, motornum+1, StepperMotors[shieldnum][motornum], shieldnum, motornum, rpm);
    }
    
    static void moveStepperMotor(byte i2caddress, byte motornum, unsigned int steps, byte direction, byte steptype) {
        byte shieldnum = (i2caddress - MIN_I2C);
        StepperMotors[shieldnum][motornum]->step(steps, direction, steptype);
        _p(MSG_MSV2_MOVE_STEPPER_MOTOR, StepperMotors[shieldnum][motornum], shieldnum, motornum, steps, direction, steptype);
    }
    
    static void releaseStepperMotor(byte i2caddress, byte motornum) {
        byte shieldnum = (i2caddress - MIN_I2C);
        StepperMotors[shieldnum][motornum]->release();
        _p(MSG_MSV2_RELEASE_STEPPER_MOTOR, shieldnum, motornum);
    }
    
    static void setSpeedStepperMotor(byte i2caddress, byte motornum, unsigned int rpm) {
        byte shieldnum = (i2caddress - MIN_I2C);
        StepperMotors[shieldnum][motornum]->setSpeed(rpm);
        _p(MSG_MSV2_SET_SPEED_STEPPER_MOTOR, shieldnum, motornum, rpm);
    }
};

class MotorShieldV2Base : public LibraryBase
{
	private: 
		const char* libName;
		
	public:
		MotorShieldV2Base(MWArduinoClass& a) : libName("Adafruit/MotorShieldV2")
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
            //_p(MSG_MSV2_ENTER_COMMAND_HANDLER, command[0], command[1], command[2], command[3], command[4]);
            byte sequenceID = command[0];
            byte cmdID = command[4];
            switch (cmdID){
                // Motor shield
                case 0x00:{  // createMotorShield
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte freqBytes[3];
                    ASCII2Binary(2, &command[7], freqBytes); 
                    unsigned int pwmfreq = freqBytes[0]+(freqBytes[1]<<8);
                    
                    _Adafruit_MotorShield::createMotorShield(i2caddress, pwmfreq) ;
                    
                    sendResponseMsg(0x00, 0, 0);
                    break;
                }
                case 0x01:{ // deleteMotorShield
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    
                    _Adafruit_MotorShield::deleteMotorShield(i2caddress);
                            
                    sendResponseMsg(0x01, 0, 0);
                    break;
                }
                
                // DC motor
                case 0x02:{ // createDCMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    _Adafruit_MotorShield::createDCMotor(i2caddress, motornum);
                            
                    sendResponseMsg(0x02, 0, 0);
                    break;
                }
                case 0x03:{ // startDCMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    
                    byte motornum = command[7];
                    
                    byte speed;
                    ASCII2Binary(1, &command[8], &speed); 

                    byte direction = command[10];
                    
                    _Adafruit_MotorShield::startDCMotor(i2caddress, motornum, speed, direction);
                    
                    sendResponseMsg(0x03, 0, 0);
                    break;    
                }
                case 0x04:{ // stopDCMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    _Adafruit_MotorShield::stopDCMotor(i2caddress, motornum);
                    
                    sendResponseMsg(0x04, 0, 0);
                    break;
                }
                case 0x05:{ // setSpeedDCMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    byte speed;
                    ASCII2Binary(1, &command[8], &speed); 

                    byte direction = command[10];
                    
                    _Adafruit_MotorShield::setSpeedDCMotor(i2caddress, motornum, speed, direction);
                    
                    sendResponseMsg(0x05, 0, 0);
                    break;
                }
                
                // Stepper Motor
                case 0x06:{ // createStepperMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    byte sprevBytes[2];
                    ASCII2Binary(2, &command[8], sprevBytes); 
                    unsigned int sprev = sprevBytes[0]+(sprevBytes[1]<<8);
                    
                    byte rpmBytes[2];
                    ASCII2Binary(2, &command[11], rpmBytes); 
                    unsigned int rpm = rpmBytes[0]+(rpmBytes[1]<<8);
                            
                    _Adafruit_MotorShield::createStepperMotor(i2caddress, motornum, sprev, rpm);
                    
                    sendResponseMsg(0x06, 0, 0);
                    break;
                }
                case 0x07:{ // releaseStepperMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    _Adafruit_MotorShield::releaseStepperMotor(i2caddress, motornum);
                    
                    sendResponseMsg(0x07, 0, 0);
                    break;
                }
                case 0x08:{ // moveStepperMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    byte stepsBytes[2];
                    ASCII2Binary(2, &command[8], stepsBytes); 
                    unsigned int steps = stepsBytes[0]+(stepsBytes[1]<<8);
                    
                    byte direction = command[11];
                    byte steptype = command[12];
                    
                    _Adafruit_MotorShield::moveStepperMotor(i2caddress, motornum, steps, direction, steptype);
                    
                    sendResponseMsg(0x08, 0, 0);
                    break;
                }
                case 0x09:{ // setSpeedStepperMotor
                    byte i2caddress;
                    ASCII2Binary(1, &command[5], &i2caddress); 
                    byte motornum = command[7];
                    
                    byte rpmBytes[2];
                    ASCII2Binary(2, &command[8], rpmBytes); 
                    unsigned int rpm = rpmBytes[0]+(rpmBytes[1]<<8);
                    
                    _Adafruit_MotorShield::setSpeedStepperMotor(i2caddress, motornum, rpm);
                    
                    sendResponseMsg(0x09, 0, 0);
                    break;
                }
                default:
                    //_p(MSG_MSV2_UNRECOGNIZED_COMMAND, cmdID);
					break;
            }
		}
};