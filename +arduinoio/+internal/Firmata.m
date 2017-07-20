classdef Firmata < arduinoio.internal.ProtocolBase
    
    % All messages are in sysex format
    % Built-in arduino and firmata message format   [START_SYSEX; 0x00; sequence_ID; payload_size; cmdID; params; END_SYSEX]
    % Server return message format                  [cmdID; payload_size; values]
    % Built-in add-on library message format        [START_SYSEX; 0x01; sequence_ID; payload_size; libID; cmdID; params; END_SYSEX]
    % Custom add-on library firmata message format  [START_SYSEX; 0x01; sequence_ID; payload_size; libID; msg; END_SYSEX]
    % Server return message format                  [cmdID; payload_size; values]
    % Note: During sending, payload_size isn't used for now and is defaulted to [0x01 0x01]
    %       During receiving, payload_size is the size of the actual returned value
 
    %   Copyright 2014 The MathWorks, Inc.

    properties(Access = private, Constant = true)
        GET_SERVER_INFO          = hex2dec('01')
        RESET_PINS_STATE         = hex2dec('02')
        GET_AVAILABLE_RAM        = hex2dec('03')
        WRITE_DIGITAL_PIN        = hex2dec('10')
        READ_DIGITAL_PIN         = hex2dec('11')
        CONFIGURE_DIGITAL_PIN    = hex2dec('12')
        WRITE_PWM_VOLTAGE        = hex2dec('20')
        WRITE_PWM_DUTY_CYCLE     = hex2dec('21')
        PLAY_TONE                = hex2dec('22')
        READ_VOLTAGE             = hex2dec('30')
        SYSEX_START              = hex2dec('F0')
        SYSEX_END                = hex2dec('F7')
        NON_LIB_HEADER           = hex2dec('00')
        LIB_HEADER               = hex2dec('01')
        SCAN_I2C_BUS             = hex2dec('01')
    end
    
%% Constructor   
    methods (Access = public)
        function obj = Firmata(connectionObj, traceOn)
            obj = obj@arduinoio.internal.ProtocolBase(connectionObj, traceOn);
        end
    end
 
%% Destructor
    methods (Access=protected)
        function delete(~)
        end
    end
 
 %% Public methods - MW's implementations of firmata
    methods (Access = public)
        function writeDigitalPin(obj, pin, value)
            msg = [...
            obj.WRITE_DIGITAL_PIN
            pin; 
            value
            ];
            [~] = sendMWMessage(obj, msg);
        end
        
        function value = readDigitalPin(obj, pin)
            msg = [...
                obj.READ_DIGITAL_PIN;
                pin;
                ];
            value = sendMWMessage(obj, msg);
            if isempty(value)
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            end
            cmdID = value(1);
            if cmdID ~= obj.READ_DIGITAL_PIN
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            else
                value = value(4);
                value = double(value > 0);
            end
        end
        
        function configureDigitalPin(obj, pin, mode)
            pinmode = 0;
            switch(mode)
                case {'Input', 'Unset'}
                    pinmode = 0;
                case {'Output', 'PWM', 'Servo'}
                    pinmode = 1;
                case 'Pullup' % Input_Pullup
                    pinmode = 2;
            end

            msg = [...
                obj.CONFIGURE_DIGITAL_PIN; 
                pin; 
                pinmode;
                ];    
            [~] = sendMWMessage(obj, msg);
        end
        
        function writePWMVoltage(obj, pin, voltage, aref)
            value = uint8(floor(voltage/aref*255));
            msg = [...
                obj.WRITE_PWM_VOLTAGE;
                pin; 
                arduinoio.BinaryToASCII(value);
            ];
            [~] = sendMWMessage(obj, msg);
        end
        
        function writePWMDutyCycle(obj, pin, dutyCycle)
            value = uint8(floor(dutyCycle/1*255));
            
            msg = [...
                obj.WRITE_PWM_DUTY_CYCLE;
                pin; 
                arduinoio.BinaryToASCII(value);
            ];
            [~] = sendMWMessage(obj, msg);
        end
        
        function value = readVoltage(obj, pin, aref)   
            msg = [...
            obj.READ_VOLTAGE;
            pin
            ];  
            value = sendMWMessage(obj, msg);
            if isempty(value)
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            end
            cmdID = value(1);
            if cmdID ~= obj.READ_VOLTAGE
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            else
                value = (bitshift(value(4), 8) + value(5))/1024*aref;
            end
        end

        function playTone(obj, pin, frequency, duration)
            duration = round(duration*1000);
            
            frequency = typecast(uint16(frequency), 'uint8');
            duration = typecast(uint16(duration), 'uint8');
            
            msg = [...
                obj.PLAY_TONE;
                pin; 
                arduinoio.BinaryToASCII(frequency);
                arduinoio.BinaryToASCII(duration);
                ] ;
            [~] = sendMWMessage(obj, msg);
        end
        
        function addrs = scanI2CBus(obj, libID, bus)
            addrs = {};
            commandID = obj.SCAN_I2C_BUS;
            cmd = [commandID; bus];
            output = sendCustomMessage(obj, libID, cmd);
            if isempty(output) % no return value 
                obj.localizedError('MATLAB:arduinoio:general:communicationLostI2C', num2str(bus));
            end
            try
                returnedCMDId = output(1);
                payLoad = output(2:3);
                numAddrsFound = bitshift(payLoad(1), 8) + payLoad(2);
                if returnedCMDId ~= commandID
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                elseif numAddrsFound == hex2dec('00') % no devices found
                    % return empty addrs
                else
                    values = uint8(output(4:end));
                    addrs = cell(numAddrsFound, 1);
                    for ii = 1:numAddrsFound
                        addrs{ii} = ['0x', dec2hex(values(ii))];
                    end
                end
            catch e
                if strcmp(e.identifier, 'MATLAB:badsubscript')
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                end
                throwAsCaller(e);
            end
        end
        
        function value = getAvailableRAM(obj)
            msg = obj.GET_AVAILABLE_RAM;
            value = sendMWMessage(obj, msg);
            if isempty(value)
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            end
            cmdID = value(1);
            if cmdID ~= obj.GET_AVAILABLE_RAM
                obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
            else
                value = bitshift(value(4), 8) + value(5);
            end
        end
        
        function resetPinsState(obj)        
            msg = obj.RESET_PINS_STATE;
            [~] = sendMWMessage(obj, msg);
        end
        
        function [getInfoSuccessFlag, libNames, libIDs, board, traceOn] = getServerInfo(obj)
            msg = obj.GET_SERVER_INFO;
            libIDs = [];
            libNames = {};
            getInfoSuccessFlag = false;
            traceOn = false;
            board = '';
            try 
                value = sendMWMessage(obj, msg);
                if isempty(value)
                    return;
                end
            catch 
                 return; % do nothing
            end
            % value :  1 byte of cmdID, 2 bytes of payload_size, values
            output = regexp(char(value(4:end))', ';', 'split'); % seperate out libraries using semicolon. 
            
            try % parse returned string to get server information
                board = output{1};
                if double(output{2}) == 0
                    traceOn = true;
                end
                if isempty(output{3}) % zero libraries
                    % return empty libs
                    getInfoSuccessFlag = true;
                else
                    if strcmp(output{3}, char(0)) % unexpected returned message
                        % stop parsing
                    else
                        seperatedLibraries = output(3:end); 
                        for ii = 1:length(seperatedLibraries)
                            libIDs = [libIDs, double(seperatedLibraries{ii}(1))]; %#ok<AGROW>
                            libNames = [libNames, {seperatedLibraries{ii}(2:end)}]; %#ok<AGROW>
                        end
                        getInfoSuccessFlag = true;
                    end
                end
            catch % catch any index out of range error for wrong return message
                libIDs = [];
                libNames = {};
            end
        end
    end
    
    %% Public methods
    methods (Access = public)
        function closeTransportLayer(obj)
            closeConnection(obj.TransportLayer);
        end
        
        function openTransportLayer(obj)
            openConnection(obj.TransportLayer);
        end
 
        function value = sendCustomMessage(obj, libID, cmd, timeout)
            msg = [...
                obj.SYSEX_START;
                obj.LIB_HEADER; % all add-on library commands starts with 0x01
                obj.SequenceID;
                uint8(1); % unused payload_size
                uint8(1);
                libID;
                cmd;
                obj.SYSEX_END];
            if nargin < 4
                value = sendMessage(obj.TransportLayer, msg);
            else
                value = sendMessage(obj.TransportLayer, msg, timeout);
            end
            % To Do - add logic to check correct return sequence ID 
            if obj.SequenceID == 127
                obj.SequenceID = 0;
            else
                obj.SequenceID = obj.SequenceID + 1;
            end
        end

        function value = sendMWMessage(obj, cmd, timeout)
            msg = [...
                obj.SYSEX_START;
                obj.NON_LIB_HEADER; % all arduino and firmata commands starts with 0x00
                obj.SequenceID;
                uint8(1); % unused payload_size
                uint8(1);
                cmd;
                obj.SYSEX_END];
            if nargin < 3
                value = sendMessage(obj.TransportLayer, msg);
            else
                value = sendMessage(obj.TransportLayer, msg, timeout);
            end
            % To Do - add logic to check correct return sequence ID
            if obj.SequenceID == 127
                obj.SequenceID = 0;
            else
                obj.SequenceID = obj.SequenceID + 1;
            end
        end
    end
end
