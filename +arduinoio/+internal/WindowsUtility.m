classdef WindowsUtility < arduinoio.internal.Utility
%   Utility class used on Windows platform

%   Copyright 2014 The MathWorks, Inc.

    methods(Access = {?arduinoio.internal.UtilityCreator, ?arduinoio.accessor.UnitTest})
    % Private constructor with limited access to only utility factory class
    % and test class
        function obj = WindowsUtility
            obj.BoardInfo = arduinoio.internal.BoardInfo.getInstance();
        end
    end
    
    methods(Access = public)
        function portInfo = validatePort(obj, varargin)
            % If given port number, this function tries to identify whether it is a
            % valid Arduino board and return the detected board type
            %
            % Otherwise, it returns the first detected Arduino's port number and
            % its corresponding board type
            %
            % Note, old Arduino boards with FTDI chips are not auto-detected
            
            findFlag = false;
            if isempty(varargin) % If no input is given, find the first valid board
                [findFlag, portInfo] = findFirstDevice(obj);
                if ~findFlag
                    obj.localizedError('MATLAB:arduinoio:general:boardNotDetected');
                end
            else % If a port is given, find the matching board type
                port = varargin{1};
                cmdstr = strcat('wmic path Win32_SerialPort where DeviceID="', port, '" get PNPDeviceID');
                [status, result] = systemImpl(obj, cmdstr);
                if ~status % if a USB board is found at the given port
                    [findFlag, portInfo] = findDeviceByRegistryString(obj, result);
                    portInfo.port = {port};
                end
                
                if status || ~findFlag % No Arduino board is found at the given port
                    obj.localizedError('MATLAB:arduinoio:general:invalidPort', port);
                end
            end
        end
        
        function props = populateArduinoProperties(obj, props)
            props = populateArduinoPropertiesSharedUtility(obj, props);
            props.Port = upper(props.Port);
        end
        
        function buildInfo = setProgrammer(~, buildInfo)
            if strcmp(buildInfo.Template, 'avr')
               buildInfo.Programmer = fullfile(buildInfo.ArduinoIDEPath, 'hardware', 'tools', 'avr', 'utils', 'bin', 'make');
               if length(buildInfo.Port) > 4
                    buildInfo.Port = ['//./', buildInfo.Port];
               end
            else
               buildInfo.Programmer = fullfile(buildInfo.ArduinoIDEPath, 'hardware', 'tools', 'g++_arm_none_eabi', 'bin', 'cs-make');
            end
        end
    end
    
    methods (Access = protected)
        function [status, result] = systemImpl(~, cmdstr)
            [status, result] = system(cmdstr);
        end
    end
    
    methods (Access = private)
        function [flag, VIDPID] = findVIDPID(~, deviceStr)
        % extract VID and PID from the input device string
            % deviceStr: '"VID_2341' -> vid: '2341'
            vid = regexp(deviceStr, '(?<=VID_)\w*', 'match');
            if isempty(vid)
                flag = false;
                VIDPID = [];
            else
                flag = true;
                vid = ['0x', vid{1}];
                % deviceStr: '"PID_0041' -> pid: '0042'
                pid = regexp(deviceStr, '(?<=PID_)\w*', 'match');
                pid = ['0x', pid{1}];
                VIDPID = [vid, '_', pid];
            end
        end

        function [findFlag, firstPort] = findFirstDevice(obj)
        %  Find the first valid board
            findFlag = false;
            firstPort = [];

            cmdstr = 'wmic path Win32_SerialPort get DeviceID,PNPDeviceID';
            [status, result] = systemImpl(obj, cmdstr);
            if ~status 
                [devices, ~] = regexp(result, obj.NLFeed, 'split');
                dCount = 2;
                while dCount<=length(devices) && ~findFlag
                    [findFlag, firstPort] = findDeviceByRegistryString(obj, devices{dCount});
                    dCount = dCount+1;
                end
            end
        end

        function [findFlag, matchPort] = findDeviceByRegistryString(obj, deviceStr)
        % Check if the given device string is a valid board
            findFlag = false;
            matchPort = [];

            [idFlag, foundVIDPID] = findVIDPID(obj, deviceStr);
            if idFlag
                % Loop through all boards in boardInfo to find matching vid/pid pair
                for bCount = 1:length(obj.BoardInfo.Boards)
                    theVIDPID = obj.BoardInfo.Boards(bCount).VIDPID;
                    if ~isempty(theVIDPID) && ~isempty(strfind(strjoin(theVIDPID), lower(foundVIDPID)))
                        findFlag = true;
                        matchPort.board = obj.BoardInfo.Boards(bCount).Name;
                        % deviceStr: 'COM1 USB\VID_2341&PID_0042' -> port: 'COM1'
                        port = regexp(deviceStr, 'COM\d*','match');
                        matchPort.port = port;
                        break;
                     end
                end
            end
        end
    end
end



