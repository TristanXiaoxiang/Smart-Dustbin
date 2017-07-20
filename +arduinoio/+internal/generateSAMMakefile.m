function generateSAMMakefile(buildInfo)
% This function generates the makefile for use with compiling and
% downloading the server code for Arduino Due board

%   Copyright 2014 The MathWorks, Inc.
    
    contents = arduinoio.internal.getTemplateMakefileContent(buildInfo, 'samtemplate.mk');
    
    arduinoio.internal.generateMakefileSharedUtility(buildInfo, contents);
end