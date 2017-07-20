function output = SPPKGRoot()
% This function returns the installed root directory of Arduino I/O support package

%   Copyright 2014 The MathWorks, Inc.

output = fileparts(which('listArduinoLibraries'));

end