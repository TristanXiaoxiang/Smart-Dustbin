function uninstall3PLibraries(destdir)
%UNINSTALL3PLIBRARIES install the motor shield libraries

% Copyright 2014 The MathWorks, Inc.

IDERootDir = arduinoio.IDERoot;

rmdir(fullfile(IDERootDir, 'libraries', destdir), 's');

end