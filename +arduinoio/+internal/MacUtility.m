classdef MacUtility < arduinoio.internal.Utility
%   Utility class used on Mac platform

%   Copyright 2014 The MathWorks, Inc.
    
    methods(Access = {?arduinoio.internal.UtilityCreator, ?arduinoio.accessor.UnitTest})
    % Private constructor with limited access to only utility factory class
    % and test class
        function obj = MacUtility
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

            findFlag = false; %#ok<NASGU>
            if isempty(varargin) % If no input is given, find the first valid board
                [findFlag, portInfo] = findFirstDevice(obj);
                if ~findFlag
                    obj.localizedError('MATLAB:arduinoio:general:boardNotDetected');
                end
            else % If a port is given, find the matching board type
                port = varargin{1};
                [findFlag, portInfo] = findDeviceByPort(obj, port);

                if ~findFlag % No Arduino board is found at the given port
                    obj.localizedError('MATLAB:arduinoio:general:invalidPort', port);
                end
            end
            
            if exist([tempdir, 'MW_Arduino_log.txt'], 'file')
                delete([tempdir, 'MW_Arduino_log.txt']);
            end
        end
        
        function props = populateArduinoProperties(obj, props)
            props = populateArduinoPropertiesSharedUtility(obj, props);
        end
        
        function buildInfo = setProgrammer(~, buildInfo)
        	buildInfo.Programmer = fullfile(buildInfo.ArduinoIDEPath, 'hardware', 'tools', 'avr', 'bin', 'make');
        end
    end
    
    methods (Access = protected)
        function [status, result] = systemImpl(~, cmdstr)
            [status, result] = system(cmdstr);
        end
    end
    
    methods (Access = private)
        function VIDPID = findVIDPID(~, deviceStr)
        % extract VID and PID from the input device string
            % deviceStr: '"idVendor" = 0x2341' -> idVendor: '2341'
            matchStr = '(?<="idVendor" = 0x)\w*'; 
            idVendor = regexp(deviceStr, matchStr, 'match');
            if ~isempty(idVendor)
                vid = ['0x' repmat('0',1, 4-length(idVendor{1})) idVendor{1}]; % '231' -> '0x0231'
                matchStr = '(?<="idProduct" = 0x)\w*';
                % deviceStr: '"idProduct" = 0x7652' -> idProduct: '7653'
                idProduct = regexp(deviceStr, matchStr, 'match');
                pid = ['0x' repmat('0',1, 4-length(idProduct{1})) idProduct{1}];
                VIDPID = [vid, '_', pid];
            else
                VIDPID= [];
            end
        end

        function [findFlag, matchPort] = findDeviceByRegistryString(obj, deviceStr)
        % Check if the given device string is a valid board
            matchPort = [];
            foundVIDPID = findVIDPID(obj, deviceStr);
            findFlag = false;

            % Loop through all boards in boardInfo to find matching vid/pid
            % pair
            for bCount = 1:length(obj.BoardInfo.Boards)
                theVIDPID = obj.BoardInfo.Boards(bCount).VIDPID;
                if ~isempty(theVIDPID) && ~isempty(strfind(strjoin(theVIDPID), lower(foundVIDPID)))
                    findFlag = true;
                    matchPort.board = obj.BoardInfo.Boards(bCount).Name;
                    % deviceStr: '"locationID" = 0x12400000'
                    % port: '/dev/tty.usbmodem1241'
                    matchStr = '(?<="locationID" = 0x)\w*?(?=0)';
                    locationID = regexp(deviceStr, matchStr, 'match');
                    matchPort.port = {['/dev/tty.usbmodem', locationID{1}, '1']};
                    break;
                 end
            end
        end

        function [findFlag, matchPort] = findDeviceByPort(obj, port)
        % Find the matching device with the given port number
            [status, ~] = systemImpl(obj, ['ioreg -l -p IOUSB -x > ', tempdir, 'MW_Arduino_log.txt']);
            if status
                findFlag = false;
                matchPort = [];
            else
                fid = fopen([tempdir, 'MW_Arduino_log.txt']);
                contents = transpose(fread(fid, '*char'));
                fclose(fid);

                findFlag = false;
                matchPort = [];
                % port: 'usbmodem1241' -> '124'
                id = regexp(port, '(?<=usbmodem)\w*(?=1)', 'match');
                if ~isempty(id)
                    % id: '124' -> locationID: '"locationID" = 0x12400000'
                    locationID = ['"locationID" = 0x' id{1}, repmat('0', 1, 8-length(id{1}))];
                    tmp = regexp(contents, ['"idProduct.*?', locationID], 'match'); % search for the nearest idProduct string
                    [result, ~] = regexp(tmp, '+-o ', 'split');
                    if ~isempty(result)
                        result = result{1}; 
                        idProductStr = result{end};
                        if ~isempty(idProductStr)
                            idVendorStr = regexp(contents, [locationID, '.*?"idVendor" = 0x\w*'], 'match'); % search for the nearest idVendor string
                            device = strcat(idProductStr, idVendorStr);
                            [findFlag, matchPort] = findDeviceByRegistryString(obj, device{1});
                        end
                    end
                end
            end
        end

        function [findFlag, firstPort] = findFirstDevice(obj)
        %  Find the first valid board
            [status, ~] = systemImpl(obj, ['ioreg -l -p IOUSB -x > ', tempdir, 'MW_Arduino_log.txt']);
            if status
                findFlag = false;
                firstPort = [];
            else
                fid = fopen([tempdir, 'MW_Arduino_log.txt']);

                contents = {};
                firstPort = [];
                findFlag = false;
                % Parse ioreg output. Lines between two consecutive '+-o'
                % indicates a seperate device on the system
                tline = fgets(fid);
                while ischar(tline) && ~findFlag
                    contents = [contents, tline]; %#ok<AGROW>
                    if ~isempty(regexp(tline, '+-o ', 'ONCE'))
                        contents = strjoin(contents, obj.NLFeed); 
                        [findFlag, firstPort] = findDeviceByRegistryString(obj, contents);
                        contents = {};
                    end
                    tline = fgets(fid);
                end
                fclose(fid);

                if ~findFlag
                    contents = strjoin(contents, obj.NLFeed);
                    [findFlag, firstPort] = findDeviceByRegistryString(obj, contents);
                end
            end
        end
    end
end




