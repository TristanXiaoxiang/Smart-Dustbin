classdef LinuxUtility < arduinoio.internal.Utility
%   Utility class used on Linux platform

%   Copyright 2014 The MathWorks, Inc.

    methods(Access = {?arduinoio.internal.UtilityCreator, ?arduinoio.accessor.UnitTest})
    % Private constructor with limited access to only utility factory class
    % and test class
        function obj = LinuxUtility
        end
    end
    
    methods(Access = public)
        function portInfo = validatePort(obj, port)
        % Check the existence of the given port, return it back if found
            cmdstr = 'ls /dev/ttyACM* /dev/ttyUSB* /dev/ttyS*';
            [~, result] = systemImpl(obj, cmdstr);
            if ~isempty(strfind(result, port))
                portInfo = port;
            else
                obj.localizedError('MATLAB:arduinoio:general:invalidPort', port);            
            end
        end
        
        function props = populateArduinoProperties(obj, props)
            [isPref, thePref] = getPreferences(obj);
            if isempty(props.Port) % calling constructor without parameters
                if isPref
                    % Port and Board population
                    try
                        props.Port = validatePort(obj, thePref.Port);
                    catch
                        obj.localizedError('MATLAB:arduinoio:general:boardNotDetected');
                    end
                    props.Board = thePref.Board;
                    % Libraries population
                    props.Libraries = {};
                    props.LibrariesSpecified = false;
                else % first time calling constructor without parameters
                    obj.localizedError('MATLAB:arduinoio:general:noPortFirstTime')
                end
            elseif isempty(props.Board)
                obj.localizedError('MATLAB:arduinoio:general:portWithNoBoard')
            else
                props.Port = validatePort(obj, props.Port);
                % Libraries population
                if isempty(props.Libraries) % user specify '' or {} as Libraries value
                    props.Libraries = {};
                    props.LibrariesSpecified = true;
                elseif isempty(props.Libraries{1}) % Not given libraries
                    props.Libraries = {};
                    props.LibrariesSpecified = false;
                else
                    props.LibrariesSpecified = true;
                end
            end
        end
        
        function buildInfo = setProgrammer(~, buildInfo)
            buildInfo.Programmer = 'make';        
        end
    end
    
    methods (Access = protected)
        function [status, result] = systemImpl(~, cmdstr)
            [status, result] = system(cmdstr);
        end
    end
end

