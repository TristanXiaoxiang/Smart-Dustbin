function install3PLibraries(zipfile, foldername, destdir)
%INSTALL3PLIBRARIES install the motor shield libraries

% Copyright 2014 The MathWorks, Inc.

IDERootDir = arduinoio.IDERoot;

unzip(zipfile, fullfile(IDERootDir, 'libraries'));
movefile(fullfile(IDERootDir, 'libraries', foldername), fullfile(IDERootDir, 'libraries', destdir));

end