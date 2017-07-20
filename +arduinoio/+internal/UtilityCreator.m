classdef UtilityCreator < handle
% Factory class to create utility object based on the platform  
    
%   Copyright 2014 The MathWorks, Inc.
    
    methods(Static = true, Access = public)
        function utilityObject = getInstance()
            persistent arduinoUtility;
            if isempty(arduinoUtility)
                if ispc 
                    arduinoUtility = arduinoio.internal.WindowsUtility();
                elseif ismac
                    arduinoUtility = arduinoio.internal.MacUtility();
                else
                    arduinoUtility = arduinoio.internal.LinuxUtility();
                end
            end
            utilityObject = arduinoUtility;
        end
    end
end