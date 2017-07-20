function output = IDERoot()
% This function returns the installed directory of Arduino IDE

%   Copyright 2014 The MathWorks, Inc.

if ismac
	output = fullfile(ide.internal.getArduinoDueIDERootDir, 'Arduino.app', 'Contents', 'Resources', 'Java');
else
	output = ide.internal.getArduinoDueIDERootDir;
end

end