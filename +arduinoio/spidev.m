classdef spidev < arduinoio.LibraryBase & matlab.mixin.CustomDisplay
    %SPIDEV Create a SPI device object.
    %   
    % dev = spidev(address) creates a SPI device object.
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties(SetAccess = immutable)
        ChipSelectPin
        Mode
        BitOrder
    end
    
    properties(Access = private)
        ResourceOwner
        Undo
    end
    
    properties(Access = private, Constant = true)
        MaxSPIData     = 16
    end
    
    properties(Access = private, Constant = true)
        START_SPI      = hex2dec('00')
        STOP_SPI       = hex2dec('01')
        SET_MODE       = hex2dec('02')
        SET_BIT_ORDER  = hex2dec('03')
        WRITE_READ     = hex2dec('04')
        SIZEOF = struct('int8', 1, 'uint8', 1, 'int16', 2, 'uint16', 2, ...
            'int32', 4, 'uint32', 4, 'int64', 8, 'uint64', 8)
    end
    
    properties(Access = protected, Constant = true)
        LibraryName = 'SPI'
        DependentLibraries = {}
        CXXIncludeDirectories = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'SPI'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'sam', 'libraries', 'SPI'), fullfile(arduinoio.SPPKGRoot, '+arduinoio', 'src')})
        CXXFiles = struct('avr', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'avr', 'libraries', 'SPI', 'SPI.cpp')}, ...
            'sam', {fullfile(arduinoio.IDERoot, 'hardware', 'arduino', 'sam', 'libraries', 'SPI', 'SPI.cpp')})
        CIncludeDirectories = {}
        CFiles = {}
        WrapperClassHeaderFile = 'SPIBase.h'
        WrapperClassName = 'SPIBase'
    end
    
    methods(Hidden, Access = public)
        function obj = spidev(parentObj, cspin, varargin)
            obj.ResourceOwner = 'spidev';
            count = parentObj.incrementResourceCount(obj.ResourceOwner);
            
            iUndo = 0;
            obj.Undo = [];
            
            terminal = getTerminalFromDigitalPin(parentObj, cspin);
            validateDigitalTerminal(parentObj, terminal);
            
            obj.ChipSelectPin = cspin;
            obj.Parent = parentObj;
            
            spiTerminals = parentObj.getSPITerminals();
            spiPins = [];
            if ~isempty(spiTerminals)
                prependChar = 'D';
                subsystem = 'digital';
                spiPins = parentObj.getDigitalPinsFromTerminals(spiTerminals);
            end
            
            % check for pre-reserved pins
            spiPinModes = {'MOSI', 'MISO', 'SCK', 'SS'};
            reservedPins = [];
            for idx = 1: numel(spiPins)
                try
                    configureDigitalPinWithUndo(spiPins(idx), obj.ResourceOwner, 'SPI', false);
                catch
                    resourceOwner = getResourceOwner(parentObj, spiPins(idx));
                    if (idx ~= numel(spiPins)) || ...
                       (idx == numel(spiPins) && ~strcmp(prevMode, 'Output')) || ...
                       (idx == numel(spiPins) && ~strcmp(resourceOwner, 'spidev'))
                        reservedPins = [reservedPins, idx]; %#ok<AGROW>
                    end
                end
            end
            if ~isempty(reservedPins)
                pinsDescription = '';
                for idx = 1 : numel(reservedPins)
                    pinsDescription = [pinsDescription, ...
                        prependChar, ...
                        num2str(spiPins(idx)), ...
                        '(', spiPinModes{idx}, '), ']; %#ok<AGROW>
                end
                pinsDescription(end-1:end) = [];
                obj.localizedError('MATLAB:arduinoio:general:reservedSPIPins',...
                    parentObj.Board, subsystem, pinsDescription);
            end
            
            % Check for conflict between ChipSelect and SPI pins (MOSI,
            % MISO, SCK, SS)
            if ismember(obj.ChipSelectPin, spiPins(1:end-1))
                obj.localizedError('MATLAB:arduinoio:general:conflictSPIPinsCS', ...
                    num2str(obj.ChipSelectPin),...
                    spiPinModes{find(spiPins == obj.ChipSelectPin, 1)});
            end
            
            % Chipselect pin setup
            mode = getTerminalMode(obj.Parent, obj.ChipSelectPin);
            resourceOwner = getResourceOwner(obj.Parent, obj.ChipSelectPin);
            if strcmp(mode, 'SPI') && strcmp(resourceOwner, obj.ResourceOwner) 
                % Take ownership of resource from Arduino object
                configureDigitalPinWithUndo(obj.ChipSelectPin, obj.ResourceOwner, 'Output', true); %Set pinmode
            else
                configureDigitalPinWithUndo(obj.ChipSelectPin, obj.ResourceOwner, 'Output', false);
            end
            overrideDigitalResource(obj.Parent, obj.ChipSelectPin, obj.ResourceOwner, 'SPI');
           
            if ~isempty(spiPins)
                obj.Pins = spiPins;
            else
                obj.Pins = [];
            end
            
            defaultSPIMode = 0;
            defaultBitOrder = 'msbfirst';
            if count > 1
                defaultSPIMode = parentObj.getResourceProperty(obj.ResourceOwner, 'Mode');
                defaultBitOrder = parentObj.getResourceProperty(obj.ResourceOwner, 'BitOrder');
            end
            % Mode and BitOrder should be only set once in the end to avoid
            % incorrect server call
            try
                p = inputParser;
                addParameter(p, 'Mode', defaultSPIMode);
                addParameter(p, 'BitOrder', defaultBitOrder);
                parse(p, varargin{:});
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyName',...
                    obj.ResourceOwner, ...
                    arduinoio.internal.renderCellArrayOfStringsToString(p.Parameters, ', '));
            end
            
            bitOrderValues = {'msbfirst', 'lsbfirst'};
            obj.Mode = arduinoio.internal.validateIntParameterRanged('SPI mode', p.Results.Mode, 0, 3);
            try
                obj.BitOrder = validatestring(p.Results.BitOrder, bitOrderValues);
            catch
                obj.localizedError('MATLAB:arduinoio:general:invalidNVPropertyValue',...
                    obj.ResourceOwner, ...
                    'BitOrder', ...
                    arduinoio.internal.renderCellArrayOfStringsToString(bitOrderValues, ', '));
            end
            
            % Uno/Mega SPI Property Conflict
            if count == 1
                parentObj.setResourceProperty(obj.ResourceOwner, 'Mode', obj.Mode);
                parentObj.setResourceProperty(obj.ResourceOwner, 'BitOrder', obj.BitOrder);
            else
                mcu = obj.Parent.getMCU();
                if ~strcmp(mcu, 'cortex-m3')
                    if obj.Mode ~= defaultSPIMode
                        obj.localizedError('MATLAB:arduinoio:general:propertyConflict',...
                            parentObj.Board, 'Mode', 'spidev');
                    end
                    if ~strcmp(obj.BitOrder, defaultBitOrder)
                        obj.localizedError('MATLAB:arduinoio:general:propertyConflict',...
                            parentObj.Board, 'BitOrder', 'spidev');
                    end
                end
            end
            
            setMode(obj);
            setBitOrder(obj);
            startSPI(obj, count);
            
            obj.Undo = [];
            
            function configureDigitalPinWithUndo(pin, resourceOwner, pinMode, forceConfig)
                prevMode = configureDigitalResource(parentObj, pin);
                prevResourceOwner = getResourceOwner(parentObj, pin);
                iUndo = iUndo + 1;
                obj.Undo(iUndo).Pin = pin;
                obj.Undo(iUndo).ResourceOwner = prevResourceOwner;
                obj.Undo(iUndo).PinMode = prevMode;
                configureDigitalResource(parentObj, pin, resourceOwner, pinMode, forceConfig);
            end
        end
    end
    
    methods (Access=protected)
        function delete(obj)
            try
                count = decrementResourceCount(obj.Parent, obj.ResourceOwner);
                stopSPI(obj, count);

                parentObj = obj.Parent;
                spiTerminals = parentObj.getSPITerminals();
                spiPins = parentObj.getDigitalPinsFromTerminals(spiTerminals);
                
                if isempty(obj.Undo)
                    if count == 0
                        for idx = 1: numel(spiPins)
                            configureDigitalResource(parentObj, spiPins(idx), obj.ResourceOwner, 'Unset', false);
                        end
                        configureDigitalResource(parentObj, obj.ChipSelectPin, obj.ResourceOwner, 'Unset', false);
                    else
                        if ismember(obj.ChipSelectPin, spiPins)
                            configureDigitalResource(parentObj, obj.ChipSelectPin, obj.ResourceOwner, 'SPI', true);
                        else
                            configureDigitalResource(parentObj, obj.ChipSelectPin, obj.ResourceOwner, 'Unset', true);
                        end
                    end
                else
                    % Construction failed, revert any pins back to their
                    % original states
                    for idx = 1:numel(obj.Undo)
                        clearDigitalResource(parentObj, obj.Undo(idx).Pin);
                        configureDigitalResource(parentObj, obj.Undo(idx).Pin, obj.Undo(idx).ResourceOwner, obj.Undo(idx).PinMode, true); 
                    end
                end
            catch
                % Do not throw errors on destroy.
                % This may result from an incomplete construction.
            end
        end
    end
    
    methods(Access = public)
        function dataOut = writeRead(obj, dataIn, dataPrecision)
            %   Write and read binary data from SPI device.
            %
            %   Syntax:
            %   dataOut = writeRead(dev,dataIn)
            %   dataOut = writeRead(dev,dataIn,dataPrecision)
            %
            %   Description: Writes the data, dataIn, to the device and reads
            %   the data available, dataOut, from the device as a result of
            %   writing dataIn
            %
            %   dataPrecision - Data Precision 'uint8' (default) | 'uint16'
            %
            %   Example:
            %       a = arduino();
            %       dev = spidev(a, 7);
            %       dataIn = [2 0 0 255];
            %       dataOut = writeRead(dev,dataIn);
            %
            %   Input Arguments:
            %   dev     - SPI device
            %   dataIn  - Data to write to the device (double).
            %
            %   Output Argument:
            %   dataOut - Available data read from the device (double)
            
            commandID = obj.WRITE_READ;
            
            if nargin < 3
                castDataOut = false;
                dataPrecision = 'uint8';
            else
                castDataOut = true;
                dataPrecision = validatestring(dataPrecision, {'uint8', 'uint16'});
            end
            
            numBytes = obj.SIZEOF.(dataPrecision);
            maxValue = 2^(numBytes*8)-1;
            
            try
                dataInLen = size(dataIn,2);
                if dataInLen*numBytes > obj.MaxSPIData
                    obj.localizedError('MATLAB:arduinoio:general:maxSPIData');
                end
                cmd = [obj.ChipSelectPin; arduinoio.BinaryToASCII(uint8(dataInLen*numBytes))];
                tmp = [];
                for ii = 1:dataInLen
                    val = arduinoio.internal.validateIntParameterRanged(...
                        ['dataIn(' num2str(ii) ')'], ...
                        dataIn(ii), ...
                        0, ...
                        maxValue);
                    val = cast(val, dataPrecision);
                    val = typecast(val, 'uint8');
                    for jj = 1:numBytes
                        % Little endian
                        tmp = [tmp; val(1+numBytes-jj)]; %#ok<AGROW>
                    end
                end
                cmd = [cmd; arduinoio.BinaryToASCII(tmp)]; 
                
                % Returned data
                %
                output = sendCommand(obj, obj.LibraryName, commandID, cmd);
                returnedCMDId = output(1);
                if returnedCMDId ~= obj.WRITE_READ
                    obj.localizedError('MATLAB:arduinoio:general:connectionIsLost');
                else
                    returnedData = output(4:end)';
                    dataOutLen = size(returnedData,2)/numBytes;
                    if castDataOut
                        switch numBytes
                            case 1
                                dataOut = uint8(zeros(1, dataOutLen));
                            case 2
                                dataOut = uint16(zeros(1, dataOutLen));
                            case 4
                                dataOut = uint32(zeros(1, dataOutLen));
                            case 8
                                dataOut = uint64(zeros(1, dataOutLen));
                        end
                    else
                        dataOut = zeros(1, dataOutLen);
                    end
                    for ii = 1:dataOutLen
                        returnedDataIdx = ((ii-1)*numBytes)+1;
                        for jj = 1:numBytes
                            dataOut(ii) = dataOut(ii) + ...
                                returnedData(returnedDataIdx + jj - 1) * 2^(8*(numBytes-jj));
                        end
                    end
                end
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods (Access = private)
        function startSPI(obj, count)
            mcu = obj.Parent.getMCU();
            if count > 1 && ~strcmp(mcu, 'cortex-m3')
                % Already started
                % Atmel MCU's call SPI.begin without specifying CS
                % One call is sufficient for all SPI devices.
                %
                return;
            end
            commandID = obj.START_SPI;
            try
                cmd = obj.ChipSelectPin;
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function stopSPI(obj, count)
            mcu = obj.Parent.getMCU();
            if count > 0 && ~strcmp(mcu, 'cortex-m3')
                % Other SPI devices still exist
                % Atmel MCU's call SPI.end without specifying CS
                % One call is sufficient for all SPI devices.
                %
                return;
            end
            
            commandID = obj.STOP_SPI;
            try
                cmd = obj.ChipSelectPin;
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods (Access = private)
        function setMode(obj)
            commandID = obj.SET_MODE;
            try
                switch obj.Mode
                    case 0
                        theMode = hex2dec('00');
                    case 1
                        theMode = hex2dec('04');
                    case 2
                        theMode = hex2dec('08');
                    case 3
                        theMode = hex2dec('0C');
                    otherwise
                end
                cmd = [obj.ChipSelectPin; theMode];
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
        
        function setBitOrder(obj)
            commandID = obj.SET_BIT_ORDER;
            try
                switch obj.BitOrder
                    case 'lsbfirst'
                        theOrder = 0;
                    case 'msbfirst'
                        theOrder = 1;
                    otherwise
                end
                cmd = [obj.ChipSelectPin; theOrder];
                sendCommand(obj, obj.LibraryName, commandID, cmd);
            catch e
                throwAsCaller(e);
            end
        end
    end
    
    methods(Access = protected)
        function output = sendCommand(obj, libName, commandID, varargin)
            cmd = commandID;
            if nargin > 3
                cmd = [cmd; varargin{1}];
            end
            output = sendCustomMessage(obj.Parent, libName, cmd);
        end
    end
    
    methods (Access = protected)
        function displayScalarObject(obj)
            header = getHeader(obj);
            header = arduinoio.internal.insertHelpLinkInDisplay(header);
            disp(header);
            
            parentObj = obj.Parent;
            SPITerminals = parentObj.getSPITerminals();
            
            if isempty(obj.Pins)
                spiPins = 'ICSP-4(MOSI), ICSP-1(MISO), ICSP-3(SCK)';
            else
                isAnalog = parentObj.IsAnalogTerminal(SPITerminals(1));
                if isAnalog
                    prependChar = 'A';
                else
                    prependChar = 'D';
                end
                
                spiPinModes = {'MOSI', 'MISO', 'SCK', 'SS'};
                spiPins = [];
                for ii = 1:numel(obj.Pins)
                    spiPins = [spiPins sprintf([prependChar '%d(%s), '], obj.Pins(ii), spiPinModes{ii})]; %#ok<AGROW>
                end
                spiPins(end-1:end) = [];
            end
            
            % Display main options
            fprintf('    ChipSelectPin: %-15d\n', obj.ChipSelectPin);
            fprintf('             Pins: %s\n', spiPins);
            fprintf('             Mode: %-15d (0, 1, 2 or 3)\n', obj.Mode);
            fprintf('         BitOrder: %-15s (''msbfirst'' or ''lsbfirst'')\n', obj.BitOrder');
            fprintf('\n');
                  
            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end
