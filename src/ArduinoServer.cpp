/*
  ArduinoServer.cpp 
  Copyright (C) 2014 MathWorks.  All rights reserved.
 
  See file LICENSE.txt for licensing terms.
*/
#ifdef ARDUINO_ARCH_SAM
#define ARDUINO_MAIN
#endif

#include "MWArduino.h"

int main(void)
{
	init();

    #ifdef ARDUINO_ARCH_SAM
	delay(1);
	
	#if defined(USBCON)
		USBDevice.attach();
	#endif
        
    #endif
        
    #ifdef ARDUINO_ARCH_AVR
    #if defined(USBCON)
        USBDevice.attach();
    #endif
    #endif
	
	MWArduino.begin(115200);
	
	for(;;)
	{
		MWArduino.update();
        if (serialEventRun) serialEventRun();
	}
	
  return 0;
}