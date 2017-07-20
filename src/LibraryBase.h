/*
  LibraryBase.h - MathWorks Arduino library
  Copyright (C) 2014 MathWorks.  All rights reserved.
*/

#ifndef LibraryBase_h
#define LibraryBase_h

class LibraryBase{
	public:
		virtual const char* getLibraryName() const = 0;
		
	public:
		virtual void commandHandler(byte* command) = 0;
};

#endif