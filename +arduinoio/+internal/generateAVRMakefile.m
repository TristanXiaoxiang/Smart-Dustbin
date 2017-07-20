function generateAVRMakefile(buildInfo)
% This function generates the makefile for use with compiling and
% downloading the server code for Arduino boards with AVR processor

%   Copyright 2014 The MathWorks, Inc.
    
    contents = arduinoio.internal.getTemplateMakefileContent(buildInfo, 'avrtemplate.mk');
    
    contents = strrep(contents, '[variant]', buildInfo.Variant);
    contents = strrep(contents, '[upload_rate]', buildInfo.BaudRate);
    contents = strrep(contents, '[protocol]', buildInfo.Protocol);
    
    arduinoio.internal.generateMakefileSharedUtility(buildInfo, contents);
end